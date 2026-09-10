module tl_tx_packer #(parameter WIDTH=16)( // tl_tx_packer模块：准备好的Control、Data及FC按半Flit打包
 input wire i_clk,i_rstn,i_taken, // 唯一输入时钟、同步低有效复位及实际发送提交
 input wire [6:0] i_pending, // 真实发送端口尚待发送的Data或BE半Flit数
 input wire i_auth,i_done,i_shared, // 复位间认证模式及对端初始信用状态
 input wire [20*(WIDTH+1)-1:0] i_available,i_capacity, // 唯一发送账本的实际物理信用
 input wire [2:0] i_request_budget,input wire [3:0] i_response_budget, // 实际Tx验证状态的catch预算
 input wire i_header_valid,input wire [255:0] i_header, // 已准备Control队首，直至实际header_taken保持
 input wire i_tags_valid,input wire [255:0] i_tags, // 与头部对应的AuthTags，密码计算在外部
 input wire [1:0] i_data_valid,input wire [255:0] i_data0,i_data1, // 有序Data或BE队首可见数量及两个半Flit
 input wire i_fc_valid,input wire [511:0] i_fc_flit,input wire [1:0] i_fc_msg, // 真实发布器的FC或初始化完成候选
 output reg o_valid,output reg [511:0] o_flit,output reg [1:0] o_msg, // 稳定至实际发送的完整候选
 output wire o_header_taken,o_tags_taken,output wire [1:0] o_data_taken,output wire o_fc_taken, // 分别确认实际消耗的输入队首
 output wire o_header_wait,o_capacity_shortfall // 本地等待及仍需上层处理的总容量不足
); // 模块端口声明结束
localparam [2:0] SEL_NONE=3'd0,SEL_HEADER=3'd1,SEL_FC=3'd2,SEL_DATA=3'd3,SEL_TAIL=3'd4,SEL_NOP=3'd5; // 候选来源与不消费输入的NOP
reg r_prefer_fc; // 同时可发时在FC与头部之间交替
reg [2:0] r_hold,selection; // 下游停顿时锁定来源，输入源保持未确认的队首
reg [1:0] data_count;reg tags_selected; // 当前候选实际占用的数据半数及标签
wire credit_allow,unused_credit_wait,credit_shortfall;wire [119:0] unused_requirements; // 独立整段信用提议
wire decode_valid;wire [2:0] request_count;wire [3:0] response_count,fields; // 实际字段个数
wire [7:0] unused_starts,unused_request_starts,unused_response_starts,be; // 字段起点及额外BE
wire [1:0] tenure_status;wire [31:0] data_counts; // 每个字段的已确认Data数量
wire header_format,credit_ready,budget_ready,has_data,payload_ready,header_ready,fc_ready; // 独立就绪条件
 tl_credit_admission #(.WIDTH(WIDTH)) Credit_Inst( // 头部包含全部后续Data信用需求
 .i_rstn(i_rstn),.i_control(1'b1),.i_done(i_done),.i_shared(i_shared), // 只解码准备好的Control队首
 .i_half(i_header),.i_available(i_available),.i_capacity(i_capacity), // 实际账本信用
 .o_requirements(unused_requirements),.o_allow(credit_allow),.o_wait(unused_credit_wait),.o_shortfall(credit_shortfall) // 信用准入及容量诊断
 ); // 结束整段信用实例端口连接
 tl_control_decode Decode_Inst(i_header,decode_valid,request_count,response_count,unused_starts,unused_request_starts,unused_response_starts); // 真实Control结构及catch需求
 tl_control_tenure Tenure_Inst(i_header,tenure_status,fields,data_counts,be); // 真实Control的Data与BE附带数量
assign header_format=decode_valid&&(tenure_status==2'd0)&&(fields!=4'd0)&&(!i_auth||(fields<=4'd4)); // 保留未决类型与Auth字段数量限制
assign credit_ready=header_format&&credit_allow; // 非法头部不能仅凭零需求放行
assign budget_ready=(request_count<=i_request_budget)&&(response_count<=i_response_budget); // 不超过实际Tx catch预算
assign has_data=(|data_counts)||(|be); // 任何后续Data或BE需要有序数据源
assign payload_ready=(i_pending==7'd1)?(i_data_valid>=2'd1):(i_auth?i_tags_valid:(!has_data||(i_data_valid>=2'd1))); // 尾部优先于新头部附带数据或认证标签
assign header_ready=i_header_valid&&credit_ready&&budget_ready&&payload_ready&&(i_pending<=7'd1)&&!(i_auth&&(i_pending==7'd1))&&!((i_pending==7'd1)&&i_fc_valid&&(i_fc_msg!=2'd0)); // Auth尾部和等待中的完成消息均先排空旧尾
assign fc_ready=i_fc_valid&&((i_pending==7'd0)||((i_pending==7'd1)&&(i_data_valid>=2'd1)&&(i_fc_msg==2'd0))); // 只有普通FC可与旧尾部共享Flit
always @* begin // 根据真实序列与已锁定来源选择当前候选
 selection=SEL_NONE; // 默认没有可发送候选
 if(i_rstn)begin // 复位期间不对外提议或消费输入
  if(r_hold!=SEL_NONE)selection=r_hold; // 停顿保持已选来源，允许其他源到达而不改写输出
  else if(i_pending>7'd1)begin // Data序列内部禁止Control或FC插入
   if(i_data_valid>=2'd2)selection=SEL_DATA; // 两个有序半Flit同时有效才构造完整Data Flit
  end else if(fc_ready&&(!header_ready||r_prefer_fc))selection=SEL_FC; // 轮到FC或业务不可发时先发FC
  else if(header_ready)selection=SEL_HEADER; // 信用、catch和本拍负载均已满足的头部
  else if((i_pending==7'd1)&&(i_data_valid>=2'd1))selection=SEL_TAIL; // 新头部阻塞仍以NOP加旧尾部完成前一事务
  else if((i_pending==7'd0)&&i_header_valid&&credit_ready&&!budget_ready)selection=SEL_NOP; // 显式NOP前进真实Flit计数并释放catch预算
 end // 结束复位外的候选选择
end // 结束来源选择组合逻辑
always @* begin // 被选来源组合成完整Flit以及独立消费计数
 o_valid=1'b0;o_flit=512'd0;o_msg=2'd0;data_count=2'd0;tags_selected=1'b0; // 完整默认值避免残留负载
 case(selection) // 按已确定的候选来源打包
  SEL_HEADER:begin // 新Control固定放在下半Flit
   o_valid=1'b1;o_flit[255:0]=i_header; // 只有实际taken才弹出头部
   if(i_pending==7'd1)begin o_flit[511:256]=i_data0;data_count=2'd1;end // 旧尾部交换到上半，不提前消费新数据
   else if(i_auth)begin o_flit[511:256]=i_tags;tags_selected=1'b1;end // 对应AuthTags与头部在同一个Flit
   else if(has_data)begin o_flit[511:256]=i_data0;data_count=2'd1;end // 无认证且有Data时上半消费第一条数据
  end // 结束新Control打包分支
  SEL_FC:begin // FC或完成消息来自真实发布器
   o_valid=1'b1;o_flit=i_fc_flit;o_msg=i_fc_msg; // 保持发布器原编码
   if(i_pending==7'd1)begin o_flit[511:256]=i_data0;data_count=2'd1;end // 普通FC上半携带旧Data或BE尾部
  end // 结束FC打包分支
  SEL_DATA:begin o_valid=1'b1;o_flit={i_data1,i_data0};data_count=2'd2;end // 有序两个Data或BE半Flit
  SEL_TAIL:begin o_valid=1'b1;o_flit={i_data0,256'd0};data_count=2'd1;end // 下半NOP允许旧尾部独立退休
  SEL_NOP:begin o_valid=1'b1;end // 完整零NOP推进catch预算且不确认任何输入队首
  default:begin end // 没有合法候选时保留所有零默认输出
 endcase // 结束候选负载打包选择
end // 结束负载和消费计数组合逻辑
assign o_header_taken=o_valid&&i_taken&&(selection==SEL_HEADER); // 头部只在真实发送后消费
assign o_tags_taken=o_valid&&i_taken&&tags_selected; // 标签消费与实际头部AuthTags同行
assign o_data_taken=(o_valid&&i_taken)?data_count:2'd0; // 分别确认零、一或两个有序半Flit
assign o_fc_taken=o_valid&&i_taken&&(selection==SEL_FC); // 发布信用仅由实际线上FC发送确认
assign o_header_wait=i_rstn&&i_header_valid&&!header_ready; // 数据供应、序列位置、预算或信用均可能引起本地等待
assign o_capacity_shortfall=i_rstn&&i_header_valid&&header_format&&credit_shortfall; // 保留超容量事务诊断，不自动丢弃或改写
always @(posedge i_clk)begin // 单时钟记录输出停顿时选择
 if(!i_rstn)r_hold<=SEL_NONE; // 同步复位取消尚未确认的提议
 else if(i_taken||!o_valid)r_hold<=SEL_NONE; // 完成发送或无有效候选后释放来源锁定
 else r_hold<=selection; // 首次停顿即锁定当前未消费来源
end // 结束来源锁定寄存器
always @(posedge i_clk)begin // 单时钟记录公平仲裁偏好
 if(!i_rstn)r_prefer_fc<=1'b1; // 初始化优先允许FC交换信用
 else if(o_fc_taken)r_prefer_fc<=1'b0; // FC已实际发送后让可发送头部获得下一次机会
 else if(o_header_taken)r_prefer_fc<=1'b1; // 头部已实际发送后让FC获得下一个合法Control位置
end // 结束仲裁偏好寄存器
endmodule // 结束tl_tx_packer模块
