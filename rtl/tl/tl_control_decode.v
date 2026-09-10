module tl_control_decode (input wire [255:0] i_half, output wire o_valid, output wire [2:0] o_requests, output wire [3:0] o_responses, output wire [7:0] o_field_starts, o_request_starts, o_response_starts); // 自然对齐树保持原控制半Flit结构接口
wire [223:0] unused_payload={i_half[251:224],i_half[219:192],i_half[187:160],i_half[155:128],i_half[123:96],i_half[91:64],i_half[59:32],i_half[27:0]}; // 字段payload由后续语义解析消费，本结构单元不解释
wire [3:0] k0=i_half[31:28]; // 字段候选最高四位
wire s0=(k0==4'd0)||(k0==4'd4)||(k0==4'd5); // 单sector合法类型
wire r0=(k0==4'd4)||(k0==4'd5); // 单sector响应
wire [3:0] k1=i_half[63:60]; // 字段候选最高四位
wire s1=(k1==4'd0)||(k1==4'd4)||(k1==4'd5); // 单sector合法类型
wire r1=(k1==4'd4)||(k1==4'd5); // 单sector响应
wire [3:0] k2=i_half[95:92]; // 字段候选最高四位
wire s2=(k2==4'd0)||(k2==4'd4)||(k2==4'd5); // 单sector合法类型
wire r2=(k2==4'd4)||(k2==4'd5); // 单sector响应
wire [3:0] k3=i_half[127:124]; // 字段候选最高四位
wire s3=(k3==4'd0)||(k3==4'd4)||(k3==4'd5); // 单sector合法类型
wire r3=(k3==4'd4)||(k3==4'd5); // 单sector响应
wire [3:0] k4=i_half[159:156]; // 字段候选最高四位
wire s4=(k4==4'd0)||(k4==4'd4)||(k4==4'd5); // 单sector合法类型
wire r4=(k4==4'd4)||(k4==4'd5); // 单sector响应
wire [3:0] k5=i_half[191:188]; // 字段候选最高四位
wire s5=(k5==4'd0)||(k5==4'd4)||(k5==4'd5); // 单sector合法类型
wire r5=(k5==4'd4)||(k5==4'd5); // 单sector响应
wire [3:0] k6=i_half[223:220]; // 字段候选最高四位
wire s6=(k6==4'd0)||(k6==4'd4)||(k6==4'd5); // 单sector合法类型
wire r6=(k6==4'd4)||(k6==4'd5); // 单sector响应
wire [3:0] k7=i_half[255:252]; // 字段候选最高四位
wire s7=(k7==4'd0)||(k7==4'd4)||(k7==4'd5); // 单sector合法类型
wire r7=(k7==4'd4)||(k7==4'd5); // 单sector响应
wire d0=(k1==4'd2)||(k1==4'd3); // 双sector候选
wire v0=d0||(s1&&s0); // 双sector组结构合法
wire q0=(k1==4'd3); // 双sector请求计数
wire [1:0] p0=d0 ? {1'b0,(k1==4'd2)} : ({1'b0,r1}+{1'b0,r0}); // 双sector组响应数
wire [1:0] f0=d0 ? 2'b01 : 2'b11; // 组内低sector起点
wire [1:0] a0={1'b0,q0}; // 组内请求起点
wire [1:0] b0=d0 ? {1'b0,(k1==4'd2)} : {r1,r0}; // 组内响应起点
wire d1=(k3==4'd2)||(k3==4'd3); // 双sector候选
wire v1=d1||(s3&&s2); // 双sector组结构合法
wire q1=(k3==4'd3); // 双sector请求计数
wire [1:0] p1=d1 ? {1'b0,(k3==4'd2)} : ({1'b0,r3}+{1'b0,r2}); // 双sector组响应数
wire [1:0] f1=d1 ? 2'b01 : 2'b11; // 组内低sector起点
wire [1:0] a1={1'b0,q1}; // 组内请求起点
wire [1:0] b1=d1 ? {1'b0,(k3==4'd2)} : {r3,r2}; // 组内响应起点
wire d2=(k5==4'd2)||(k5==4'd3); // 双sector候选
wire v2=d2||(s5&&s4); // 双sector组结构合法
wire q2=(k5==4'd3); // 双sector请求计数
wire [1:0] p2=d2 ? {1'b0,(k5==4'd2)} : ({1'b0,r5}+{1'b0,r4}); // 双sector组响应数
wire [1:0] f2=d2 ? 2'b01 : 2'b11; // 组内低sector起点
wire [1:0] a2={1'b0,q2}; // 组内请求起点
wire [1:0] b2=d2 ? {1'b0,(k5==4'd2)} : {r5,r4}; // 组内响应起点
wire d3=(k7==4'd2)||(k7==4'd3); // 双sector候选
wire v3=d3||(s7&&s6); // 双sector组结构合法
wire q3=(k7==4'd3); // 双sector请求计数
wire [1:0] p3=d3 ? {1'b0,(k7==4'd2)} : ({1'b0,r7}+{1'b0,r6}); // 双sector组响应数
wire [1:0] f3=d3 ? 2'b01 : 2'b11; // 组内低sector起点
wire [1:0] a3={1'b0,q3}; // 组内请求起点
wire [1:0] b3=d3 ? {1'b0,(k7==4'd2)} : {r7,r6}; // 组内响应起点
wire full0=(k3==4'd1); // 四sector请求优先覆盖内部payload
wire valid0=full0||(v1&&v0); // 四sector组合法
wire [1:0] req0=full0 ? 2'd1 : ({1'b0,q1}+{1'b0,q0}); // 平衡请求计数
wire [2:0] rsp0=full0 ? 3'd0 : ({1'b0,p1}+{1'b0,p0}); // 平衡响应计数
wire [3:0] fields0=full0 ? 4'b0001 : {f1,f0}; // 四sector字段起点
wire [3:0] requests0=full0 ? 4'b0001 : {a1,a0}; // 四sector请求起点
wire [3:0] responses0=full0 ? 4'b0000 : {b1,b0}; // 四sector响应起点
wire full1=(k7==4'd1); // 四sector请求优先覆盖内部payload
wire valid1=full1||(v3&&v2); // 四sector组合法
wire [1:0] req1=full1 ? 2'd1 : ({1'b0,q3}+{1'b0,q2}); // 平衡请求计数
wire [2:0] rsp1=full1 ? 3'd0 : ({1'b0,p3}+{1'b0,p2}); // 平衡响应计数
wire [3:0] fields1=full1 ? 4'b0001 : {f3,f2}; // 四sector字段起点
wire [3:0] requests1=full1 ? 4'b0001 : {a3,a2}; // 四sector请求起点
wire [3:0] responses1=full1 ? 4'b0000 : {b3,b2}; // 四sector响应起点
assign o_valid=valid1&&valid0; // 两半组共同合法
assign o_requests=o_valid ? ({1'b0,req1}+{1'b0,req0}) : 3'd0; // 非法结构请求计数归零
assign o_responses=o_valid ? ({1'b0,rsp1}+{1'b0,rsp0}) : 4'd0; // 非法结构响应计数归零
assign o_field_starts=o_valid ? {fields1,fields0} : 8'd0; // 非法结构位置归零
assign o_request_starts=o_valid ? {requests1,requests0} : 8'd0; // 非法结构位置归零
assign o_response_starts=o_valid ? {responses1,responses0} : 8'd0; // 非法结构位置归零
endmodule // 无寄存器纯组合解码
