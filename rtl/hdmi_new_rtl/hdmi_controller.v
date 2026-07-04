//////////////////////////////////////////////////////////////////////////////////
// HDMI Displat Driver Module
//////////////////////////////////////////////////////////////////////////////////
module hdmi_controller(
	input          clk,              // 125MHz
	output [2:0]   TMDSp, 
	output [2:0]   TMDSn,
	output         TMDSp_clock, 
	output         TMDSn_clock
);

//////////////////////////////////////////////////////////////////////////////////
// Clock Generator Instantiation
wire    clk_pix;
    wire    clk_tmds;    
    
    clock_gen #(
        .MULT_MASTER (36.25),  // 125MHz * 36.25 = 4531.25 MHz Master VCO
        .DIV_MASTER  (5),     // 4531.25 / 5 = 906.25 MHz
        .DIV_PIX     (36),    // 906.25 / 36 = 25.17 MHz (~25.2 MHz Pixel Clock)
        .DIV_TMDS    (3.6),   // 906.25 / 3.6 = 251.73 MHz (~252 MHz TMDS Clock)
        .IN_PERIOD   (8)      // 125MHz is an 8ns period
    ) clock_gen_inst (
        .clk        (clk        ),  
        .clk_pix    (clk_pix    ),  
        .clk_tmds   (clk_tmds   )   
    );
//////////////////////////////////////////////////////////////////////////////////
// Sync Signal Generator Instantiation
//////////////////////////////////////////////////////////////////////////////////
wire [11:0] sx, sy;
    wire hsync, vsync, de;
    
    sync_gen #(
        // horizontal timings (Total line width = 800 pixels)
        .HA_END     (639),   // Active Video: 640 pixels
        .HS_STA     (655),   // Front Porch: 16 pixels
        .HS_END     (751),   // Sync Pulse: 96 pixels
        .LINE       (799),   // Back Porch: 48 pixels (Total = 800)
    
        // vertical timings (Total screen height = 525 lines)
        .VA_END     (479),   // Active Video: 480 lines
        .VS_STA     (489),   // Front Porch: 10 lines
        .VS_END     (491),   // Sync Pulse: 2 lines
        .SCREEN     (524)    // Back Porch: 33 lines (Total = 525)
    ) sync_gen_inst (
        .clk_pix    (clk_pix    ),     
        .sx         (sx         ),     
        .sy         (sy         ),     
        .hsync      (hsync      ),     
        .vsync      (vsync      ),     
        .de         (de         )      
    );
/////////////////////////////////////////////////////////////////////////////////
// 8 Colour Strip Pattern Generator Logic
////////////////////////////////////////////////////////////////////////////////
reg [7:0] red, green, blue;
    always@(posedge clk_pix)
    begin
        red   <= (sx >= 320) ? 8'hFF : 8'h00;
        green <= ((sx >= 160 && sx <= 319) || (sx >= 480)) ? 8'hFF : 8'h00;
        blue  <= ((sx >= 80 && sx <= 159) || (sx >= 240 && sx <= 319) || 
                 (sx >= 400 && sx <= 479) || (sx >= 560)) ? 8'hFF : 8'h00;
    end
/////////////////////////////////////////////////////////////////////////////////
// TMDS Encoder Instntiation
////////////////////////////////////////////////////////////////////////////////
    wire [9:0] tmds_red, tmds_green, tmds_blue;
    
    tmds_enc enc_r(
        .clk    (clk_pix        ), 
        .vd     (red            ), 
        .cd     (2'b00          ), 
        .de     (de             ), 
        .tmds   (tmds_red       )
    );
    
    tmds_enc enc_g(
        .clk    (clk_pix        ), 
        .vd     (green          ), 
        .cd     (2'b00          ), 
        .de     (de             ), 
        .tmds   (tmds_green     )
    );
    
    tmds_enc enc_b(
        .clk    (clk_pix        ), 
        .vd     (blue           ), 
        .cd     ({vsync,hsync}  ), 
        .de     (de             ), 
        .tmds   (tmds_blue      )
    );

/////////////////////////////////////////////////////////////////////////////////
// Serializer Instantiation
////////////////////////////////////////////////////////////////////////////////
    wire ser_red, ser_green, ser_blue;
    
    serializer ser_r(
        .clk_pix    (clk_pix    ),
        .clk_tmds   (clk_tmds   ),
        .data_i     (tmds_red   ),
        .data_o     (ser_red    )
    );
    
    serializer ser_g(
        .clk_pix    (clk_pix    ),
        .clk_tmds   (clk_tmds   ),
        .data_i     (tmds_green ),
        .data_o     (ser_green  )
    );
    
    serializer ser_b(
        .clk_pix    (clk_pix    ),
        .clk_tmds   (clk_tmds   ),
        .data_i     (tmds_blue  ),
        .data_o     (ser_blue   )
    );

/////////////////////////////////////////////////////////////////////////////////
// Differential Output Buffers
////////////////////////////////////////////////////////////////////////////////
    OBUFDS #
    (
        .IOSTANDARD ("DEFAULT"  ),  // Specify the output I/O standard
        .SLEW       ("SLOW"     )   // Specify the output slew rate
    ) OBUFDS_red 
    (
        .O  (TMDSp[2]   ),          // Diff_p output (connect directly to top-level port)
        .OB (TMDSn[2]   ),          // Diff_n output (connect directly to top-level port)
        .I  (ser_red    )           // Buffer input
    );
    
    OBUFDS #
    (
        .IOSTANDARD("DEFAULT"),
        .SLEW("SLOW")
    ) OBUFDS_green 
    (
        .O(TMDSp[1]),
        .OB(TMDSn[1]),
        .I(ser_green)
    );
    
    OBUFDS #
    (
        .IOSTANDARD("DEFAULT"),
        .SLEW("SLOW") 
    ) OBUFDS_blue 
    (
        .O(TMDSp[0]), 
        .OB(TMDSn[0]),
        .I(ser_blue)
    );
    
    OBUFDS #
    (
        .IOSTANDARD("DEFAULT"),
        .SLEW("SLOW")
    ) OBUFDS_clock 
    (
        .O(TMDSp_clock),
        .OB(TMDSn_clock), 
        .I(clk_pix)
    );

endmodule