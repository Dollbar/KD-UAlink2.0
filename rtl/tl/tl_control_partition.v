module tl_control_partition #(parameter WIDTH=16)( // tl_control_partition模块：按总信用容量分组完整字段，保持单笔事务不变
 input wire i_clk,i_rstn,i_source_valid,i_ready,i_done,i_response,i_auth,i_shared, // 唯一时钟及同一初始化时期的类别、认证、共享状态
 input wire [255:0] i_source_control,input wire [511:0] i_source_tags, // 最多八个已准备字段及按字段排序的八个64位标签
 input wire [20*(WIDTH+1)-1:0] i_capacity, // 实际端口初始化后固定的物理容量，不是可变余额
 output wire o_valid,o_taken,o_source_taken,o_error,o_shortfall, // 分组入队确认与整个输入字段组完成确认分别返回
 output wire [255:0] o_control,o_tags,output wire [3:0] o_fields,o_end,o_cursor // 输出合法分组和本地扇区进度观察
); // 结束完整字段容量分组端口
reg [3:0] r_cursor; // 当前源中尚未入队的第一个扇区，原始字段自然对齐位置保持不变
wire decoded;wire [2:0] requests;wire [3:0] responses,total_fields; // 原始组的类别与合法字段数量
wire [7:0] starts,request_starts,response_starts,application_starts; // 实际解码树提供完整字段边界而非猜测payload位
wire [1:0] tenure_status;wire [31:0] unused_counts;wire [7:0] unused_be; // 已确认tenure合法性，不修改事务数据长度
wire [7:0] bad_fc,fit;wire [255:0] prefix[0:7];wire [3:0] prefix_fields[0:7]; // 八个可能边界及其完整字段提议
reg [3:0] selected_end,selected_fields,before_fields;reg [255:0] selected_control; // 当前最长可容纳前缀与此前已完成标签数
wire format_error;integer pick; // 静态展开边界优先级，无派生时钟或隐藏队列
 tl_control_decode Decode_Inst(i_source_control,decoded,requests,responses,starts,request_starts,response_starts); // 使用真实自然对齐树识别字段
 tl_control_tenure Tenure_Inst(i_source_control,tenure_status,total_fields,unused_counts,unused_be); // 未决编码不能绕过到容量逻辑
assign application_starts=request_starts|response_starts; // NOP/FC不拥有事务数据或认证标签
assign format_error=!decoded||(tenure_status!=2'd0)||(total_fields==4'd0)||(i_response?(requests!=3'd0):(responses!=4'd0))||(|bad_fc); // 不混类且拒绝把独立FC事件当作可重分组事务
assign o_error=i_rstn&&i_source_valid&&format_error; // 格式错误保留整组输入，禁止部分丢弃
assign o_valid=i_rstn&&i_done&&i_source_valid&&!format_error&&(selected_end!=4'd0); // 初始化容量稳定后才提出可入队分组
assign o_taken=o_valid&&i_ready;assign o_source_taken=o_taken&&(selected_end==4'd8); // 只有最后一组实际入队才释放源字段组
assign o_shortfall=i_rstn&&i_done&&i_source_valid&&!format_error&&(selected_end==4'd0); // 最早单字段也超容量时明确等待，不拆写事务
assign o_control=o_valid?selected_control:256'd0;assign o_fields=o_valid?selected_fields:4'd0;assign o_end=o_valid?selected_end:4'd0; // 无效提议不暴露旧字段或标签数量
assign o_cursor=i_rstn?r_cursor:4'd0; // 本地游标只由实际入队推进
genvar boundary,sector,tag;generate // 固定八个边界和四个输出认证槽
for(sector=0;sector<8;sector=sector+1)begin:gen_fc_check // 解码标为非事务起点的单扇区只允许全零NOP
 assign bad_fc[sector]=starts[sector]&&!application_starts[sector]&&(i_source_control[sector*32+:32]!=32'd0); // 非零FC需走独立发布器而非此接口
end // 结束源NOP字段检查
for(boundary=0;boundary<8;boundary=boundary+1)begin:gen_prefix // 每个候选只在完整字段边界结束
 localparam integer END_VALUE=boundary+1;localparam [3:0] END_SECTOR=END_VALUE[3:0]; // 四位表示结束扇区一至八
 wire complete_boundary,allowed,unused_wait,unused_shortfall;wire [119:0] unused_requirements;wire [7:0] selected_starts; // 每组容量检查与字段计数
 if(boundary==7)begin:gen_last // 第八扇区之后必为完整源结尾
  assign complete_boundary=1'b1; // 不访问边界以外的起点位
 end else begin:gen_inner // 中间边界必须是下一个已解码字段起点
  assign complete_boundary=starts[boundary+1]; // 禁止在双扇区或四扇区字段内部切断
 end // 结束字段边界选择
 for(sector=0;sector<8;sector=sector+1)begin:gen_sector // 保留自然对齐位置，省略字段用NOP清零
  localparam [3:0] POSITION=sector[3:0]; // 将生成索引限制到本地游标比较宽度
  assign prefix[boundary][sector*32+:32]=((r_cursor<=POSITION)&&(sector<=boundary))?i_source_control[sector*32+:32]:32'd0; // 所有原字段位完整保留或整体由边界排除
  assign selected_starts[sector]=application_starts[sector]&&(r_cursor<=POSITION)&&(sector<=boundary); // 只计入仍属当前前缀的事务字段
 end // 结束候选扇区掩码
 assign prefix_fields[boundary]={3'd0,selected_starts[0]}+{3'd0,selected_starts[1]}+{3'd0,selected_starts[2]}+{3'd0,selected_starts[3]}+{3'd0,selected_starts[4]}+{3'd0,selected_starts[5]}+{3'd0,selected_starts[6]}+{3'd0,selected_starts[7]}; // 四位完整表示零至八个字段
 tl_credit_admission #(.WIDTH(WIDTH)) Capacity_Inst( // 只比较初始化容量，真实余额在实际线上准入时再次检查
 .i_rstn(i_rstn),.i_control(1'b1),.i_done(i_done),.i_shared(i_shared),.i_half(prefix[boundary]),.i_available(i_capacity),.i_capacity(i_capacity), // 不提前扣减、也不复制信用账本
 .o_requirements(unused_requirements),.o_allow(allowed),.o_wait(unused_wait),.o_shortfall(unused_shortfall) // 复用已验证的完整CMD/Data需求与共享池合并
 ); // 结束每个前缀容量检查
 assign fit[boundary]=(r_cursor<END_SECTOR)&&complete_boundary&&(prefix_fields[boundary]!=4'd0)&&(!i_auth||(prefix_fields[boundary]<=4'd4))&&allowed; // 完整非空字段组同时满足容量与Auth槽限制
end // 结束八种完整前缀候选
for(tag=0;tag<4;tag=tag+1)begin:gen_tag // 标签跟随未修改的事务字段顺序重新从低槽开始
 localparam [3:0] TAG_POSITION=tag[3:0]; // 输出槽编号与字段数量匹配
 wire [3:0] source_tag;assign source_tag=before_fields+TAG_POSITION; // 已完成字段数量决定输入标签索引
 assign o_tags[tag*64+:64]=(o_valid&&i_auth&&(TAG_POSITION<selected_fields))?i_source_tags[source_tag*64+:64]:64'd0; // 所有未使用槽必须清零
end // 结束认证标签槽映射
endgenerate // 结束完整字段、容量与标签生成结构
always @* begin // 选择最长合格完整前缀，并数出已入队标签
 selected_end=4'd0;selected_fields=4'd0;selected_control=256'd0;before_fields=4'd0; // 完整组合默认值
 for(pick=0;pick<8;pick=pick+1)begin // 顺序覆盖实现最高完整边界优先
  if(fit[pick])begin selected_end=pick[3:0]+4'd1;selected_fields=prefix_fields[pick];selected_control=prefix[pick];end // 合格边界永不切割原始字段
  if(application_starts[pick]&&(pick[3:0]<r_cursor))before_fields=before_fields+4'd1; // NOP不占认证槽
 end // 结束最长前缀与标签前缀计数
end // 结束组合分组提议
always @(posedge i_clk)begin // 唯一状态记录实际下游头部队列的接纳进度
 if(!i_rstn)r_cursor<=4'd0; // 同步复位取消旧批次所有权
 else if(o_taken)r_cursor<=o_source_taken?4'd0:selected_end; // 停顿或超容量时完整保持源游标
end // 结束分组游标寄存器
endmodule // 结束tl_control_partition模块
