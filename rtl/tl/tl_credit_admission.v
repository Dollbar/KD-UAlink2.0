module tl_credit_admission #(parameter WIDTH=16)( // tl_credit_admission模块：当前确认字段的整段信用准入
 input wire i_rstn,i_control,i_done,i_shared, // 同步复位电平及真实发送序列边界
 input wire [255:0] i_half, // 待发送Control半Flit，数据阶段不解码
 input wire [20*(WIDTH+1)-1:0] i_available,i_capacity, // 唯一发送账本的当前物理槽计数
 output reg [119:0] o_requirements, // 每物理槽六位，容纳八个四Beat响应
 output wire o_allow,o_wait,o_shortfall // 可准入、暂缺信用、总容量不足诊断
); // 原子头部准入，不改变线上逐Data对扣费时刻
generate if(WIDTH<8||WIDTH>16)begin:gen_invalid_width // 实际端口信用宽度契约
 tl_credit_admission_invalid_WIDTH invalid_parameter(); // 非法参数明确拒绝展开
end endgenerate // 参数合法性检查结束
wire [1:0] status;wire [3:0] unused_fields;wire [31:0] w_counts;wire [7:0] unused_be; // 规范字段附带数量
wire valid;wire [2:0] unused_requests;wire [3:0] unused_responses;wire [7:0] unused_starts,w_req,w_rsp;wire [39:0] w_slots; // 字段位置及归属
wire eligible_format; // 未决及无效tenure均不得准入
assign eligible_format=valid&&(status==2'd0); // 未决及无效tenure均不得准入
wire [19:0] available_fit,capacity_fit; // 所有物理槽共同满足才准入
integer field,slot; // 固定八字段展开索引
 tl_control_tenure u_tenure(i_half,status,unused_fields,w_counts,unused_be); // 复用已核对tenure解码
 tl_control_decode u_decode(i_half,valid,unused_requests,unused_responses,unused_starts,w_req,w_rsp); // 只解释真正字段起点
wire [1:0] w_vc0; // sector0字段VC
assign w_vc0=(i_half[127:124]==4'd1)?i_half[117:116]:((i_half[63:60]==4'd2)?i_half[59:58]:(i_half[63:60]==4'd3)?i_half[56:55]:i_half[27:26]); // sector0字段VC
wire w_pool0; // sector0字段Pool
assign w_pool0=(i_half[127:124]==4'd1)?i_half[102]:((i_half[63:60]==4'd2)?i_half[46]:(i_half[63:60]==4'd3)?i_half[41]:i_half[14]); // sector0字段Pool
wire [2:0] w_lane0; // Pool或专用VC
assign w_lane0=w_pool0?3'd0:({1'b0,w_vc0}+3'd1); // Pool或专用VC
assign w_slots[0+:5]=(w_req[0]?5'd10:5'd15)+{2'd0,w_lane0}; // 请求与响应Data类
wire [1:0] w_vc1; // sector1字段VC
assign w_vc1=i_half[59:58]; // sector1字段VC
wire w_pool1; // sector1字段Pool
assign w_pool1=i_half[46]; // sector1字段Pool
wire [2:0] w_lane1; // Pool或专用VC
assign w_lane1=w_pool1?3'd0:({1'b0,w_vc1}+3'd1); // Pool或专用VC
assign w_slots[5+:5]=(w_req[1]?5'd10:5'd15)+{2'd0,w_lane1}; // 请求与响应Data类
wire [1:0] w_vc2; // sector2字段VC
assign w_vc2=(i_half[127:124]==4'd2)?i_half[123:122]:(i_half[127:124]==4'd3)?i_half[120:119]:i_half[91:90]; // sector2字段VC
wire w_pool2; // sector2字段Pool
assign w_pool2=(i_half[127:124]==4'd2)?i_half[110]:(i_half[127:124]==4'd3)?i_half[105]:i_half[78]; // sector2字段Pool
wire [2:0] w_lane2; // Pool或专用VC
assign w_lane2=w_pool2?3'd0:({1'b0,w_vc2}+3'd1); // Pool或专用VC
assign w_slots[10+:5]=(w_req[2]?5'd10:5'd15)+{2'd0,w_lane2}; // 请求与响应Data类
wire [1:0] w_vc3; // sector3字段VC
assign w_vc3=i_half[123:122]; // sector3字段VC
wire w_pool3; // sector3字段Pool
assign w_pool3=i_half[110]; // sector3字段Pool
wire [2:0] w_lane3; // Pool或专用VC
assign w_lane3=w_pool3?3'd0:({1'b0,w_vc3}+3'd1); // Pool或专用VC
assign w_slots[15+:5]=(w_req[3]?5'd10:5'd15)+{2'd0,w_lane3}; // 请求与响应Data类
wire [1:0] w_vc4; // sector4字段VC
assign w_vc4=(i_half[255:252]==4'd1)?i_half[245:244]:((i_half[191:188]==4'd2)?i_half[187:186]:(i_half[191:188]==4'd3)?i_half[184:183]:i_half[155:154]); // sector4字段VC
wire w_pool4; // sector4字段Pool
assign w_pool4=(i_half[255:252]==4'd1)?i_half[230]:((i_half[191:188]==4'd2)?i_half[174]:(i_half[191:188]==4'd3)?i_half[169]:i_half[142]); // sector4字段Pool
wire [2:0] w_lane4; // Pool或专用VC
assign w_lane4=w_pool4?3'd0:({1'b0,w_vc4}+3'd1); // Pool或专用VC
assign w_slots[20+:5]=(w_req[4]?5'd10:5'd15)+{2'd0,w_lane4}; // 请求与响应Data类
wire [1:0] w_vc5; // sector5字段VC
assign w_vc5=i_half[187:186]; // sector5字段VC
wire w_pool5; // sector5字段Pool
assign w_pool5=i_half[174]; // sector5字段Pool
wire [2:0] w_lane5; // Pool或专用VC
assign w_lane5=w_pool5?3'd0:({1'b0,w_vc5}+3'd1); // Pool或专用VC
assign w_slots[25+:5]=(w_req[5]?5'd10:5'd15)+{2'd0,w_lane5}; // 请求与响应Data类
wire [1:0] w_vc6; // sector6字段VC
assign w_vc6=(i_half[255:252]==4'd2)?i_half[251:250]:(i_half[255:252]==4'd3)?i_half[248:247]:i_half[219:218]; // sector6字段VC
wire w_pool6; // sector6字段Pool
assign w_pool6=(i_half[255:252]==4'd2)?i_half[238]:(i_half[255:252]==4'd3)?i_half[233]:i_half[206]; // sector6字段Pool
wire [2:0] w_lane6; // Pool或专用VC
assign w_lane6=w_pool6?3'd0:({1'b0,w_vc6}+3'd1); // Pool或专用VC
assign w_slots[30+:5]=(w_req[6]?5'd10:5'd15)+{2'd0,w_lane6}; // 请求与响应Data类
wire [1:0] w_vc7; // sector7字段VC
assign w_vc7=i_half[251:250]; // sector7字段VC
wire w_pool7; // sector7字段Pool
assign w_pool7=i_half[238]; // sector7字段Pool
wire [2:0] w_lane7; // Pool或专用VC
assign w_lane7=w_pool7?3'd0:({1'b0,w_vc7}+3'd1); // Pool或专用VC
assign w_slots[35+:5]=(w_req[7]?5'd10:5'd15)+{2'd0,w_lane7}; // 请求与响应Data类
always @* begin // 整个Control所需CMD及后续全部Data信用
 o_requirements=120'd0;slot=0; // 完整默认值，无隐含状态
 if(i_rstn&&i_control&&eligible_format)begin // 数据和消息阶段不得误解负载
  for(field=0;field<8;field=field+1)begin // 八个固定字段位置
   if(w_req[field]||w_rsp[field])begin // 仅CMD字段有需求，FC与NOP无需求
    slot={27'd0,w_slots[field*5+:5]}; // 保留Request/Response及Pool/VC归属
    o_requirements[(slot-10)*6+:6]=o_requirements[(slot-10)*6+:6]+6'd1; // 每命令一个信用
    o_requirements[slot*6+:6]=o_requirements[slot*6+:6]+{3'd0,w_counts[field*4+1+:3]}; // 两个Data半Flit一信用，BE不额外计费
   end // 字段资源计数结束
  end // 字段累计结束
  if(i_shared)begin // 仅两个Data Pool合并，CMD及专用VC保持独立
   o_requirements[60+:6]=o_requirements[60+:6]+o_requirements[90+:6]; // 共享池总需求最多三十二
   o_requirements[90+:6]=6'd0; // 第二逻辑池在物理账本中已并入槽十
  end // 共享归一化结束
 end // 合法Control判断结束
end // 无寄存器的准入需求结束
genvar j;generate for(j=0;j<20;j=j+1)begin:credit_fit // 每槽独立等宽比较
 wire [WIDTH:0] need; // 六位需求无损扩宽
assign need={{(WIDTH-5){1'b0}},o_requirements[j*6+:6]}; // 六位需求无损扩宽
 assign available_fit[j]=need<=i_available[j*(WIDTH+1)+:WIDTH+1]; // 不借用尚未接收的返还
 assign capacity_fit[j]=need<=i_capacity[j*(WIDTH+1)+:WIDTH+1]; // 区分等待与无法容纳
end endgenerate // 比较器结束
assign o_allow=i_rstn&&(!i_control||(eligible_format&&((o_requirements==120'd0)||(i_done&&(&available_fit))))); // FC启动无信用依赖
assign o_shortfall=i_rstn&&i_control&&eligible_format&&i_done&&!( &capacity_fit); // 本地策略诊断，不生成新的线消息
assign o_wait=i_rstn&&i_control&&eligible_format&&!o_allow&&!o_shortfall; // 初始化或已用信用等待
endmodule // 结束tl_credit_admission模块
