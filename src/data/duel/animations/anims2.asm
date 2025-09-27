AnimData107::
	frame_table AnimFrameTable35
	frame_data 6, 5, 40, -24
	frame_data 7, 5, -20, -16
	frame_data 0, 5, -20, -8
	frame_data 1, 5, -24, 10
	frame_data 2, 5, -6, 20
	frame_data 3, 5, 12, 16
	frame_data 4, 5, 20, 6
	frame_data 5, 5, 16, -6
	frame_data 6, 5, 0, -14
	frame_data 7, 5, -16, -8
	frame_data 0, 4, 0, 0
	frame_data 1, 4, 0, 0
	frame_data 2, 4, 0, 0
	frame_data 3, 4, 0, 0
	frame_data 8, 4, 0, 0
	frame_data 9, 5, 0, 0
	frame_data 10, 5, 0, 0
	frame_data 11, 5, 0, 0
	frame_data 11, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable35::
	dw .data_ac86e
	dw .data_ac893
	dw .data_ac8bc
	dw .data_ac8e9
	dw .data_ac912
	dw .data_ac937
	dw .data_ac960
	dw .data_ac989
	dw .data_ac9b2
	dw .data_ac9e3
	dw .data_ac9f8
	dw .data_aca0d

.data_ac86e
	db 9 ; size
	db -16, 16, 5, $0
	db -8, 8, 6, $0
	db -8, 16, 4, $0
	db -16, 8, 4, $0
	db -24, 8, 6, $0
	db -24, -8, 0, $0
	db -24, 0, 1, $0
	db -16, -8, 2, $0
	db -16, 0, 3, $0

.data_ac893
	db 10 ; size
	db -24, 0, 4, $0
	db -16, 8, 5, $0
	db -24, 8, 6, $0
	db -8, -24, 0, OAM_YFLIP
	db -8, -16, 1, OAM_YFLIP
	db -16, -24, 2, OAM_YFLIP
	db -16, -16, 0, OAM_YFLIP
	db -16, -8, 1, OAM_YFLIP
	db -24, -16, 2, OAM_YFLIP
	db -24, -8, 3, OAM_YFLIP

.data_ac8bc
	db 11 ; size
	db -24, -16, 4, $0
	db -24, -32, 5, $0
	db -32, -24, 6, $0
	db -8, -16, 0, OAM_XFLIP | OAM_YFLIP
	db -8, -24, 1, OAM_XFLIP | OAM_YFLIP
	db -16, -16, 2, OAM_XFLIP | OAM_YFLIP
	db -16, -24, 3, OAM_XFLIP | OAM_YFLIP
	db 8, -16, 0, OAM_XFLIP | OAM_YFLIP
	db 8, -24, 1, OAM_XFLIP | OAM_YFLIP
	db 0, -16, 2, OAM_XFLIP | OAM_YFLIP
	db 0, -24, 3, OAM_XFLIP | OAM_YFLIP

.data_ac8e9
	db 10 ; size
	db 0, -24, 6, $0
	db 0, -16, 5, $0
	db 8, -24, 4, $0
	db -8, -24, 4, $0
	db -8, -32, 6, $0
	db -24, -24, 6, $0
	db 16, -8, 0, OAM_XFLIP | OAM_YFLIP
	db 16, -16, 1, OAM_XFLIP | OAM_YFLIP
	db 8, -8, 2, OAM_XFLIP | OAM_YFLIP
	db 8, -16, 3, OAM_XFLIP | OAM_YFLIP

.data_ac912
	db 9 ; size
	db 8, -24, 5, OAM_XFLIP | OAM_YFLIP
	db 0, -16, 6, OAM_XFLIP | OAM_YFLIP
	db 0, -24, 4, OAM_XFLIP | OAM_YFLIP
	db 8, -16, 4, OAM_XFLIP | OAM_YFLIP
	db 16, -16, 6, OAM_XFLIP | OAM_YFLIP
	db 16, 0, 0, OAM_XFLIP | OAM_YFLIP
	db 16, -8, 1, OAM_XFLIP | OAM_YFLIP
	db 8, 0, 2, OAM_XFLIP | OAM_YFLIP
	db 8, -8, 3, OAM_XFLIP | OAM_YFLIP

.data_ac937
	db 10 ; size
	db 16, -8, 4, OAM_XFLIP | OAM_YFLIP
	db 8, -16, 5, OAM_XFLIP | OAM_YFLIP
	db 16, -16, 6, OAM_XFLIP | OAM_YFLIP
	db 0, 16, 0, OAM_XFLIP
	db 0, 8, 1, OAM_XFLIP
	db 8, 16, 2, OAM_XFLIP
	db 8, 8, 0, OAM_XFLIP
	db 8, 0, 1, OAM_XFLIP
	db 16, 8, 2, OAM_XFLIP
	db 16, 0, 3, OAM_XFLIP

.data_ac960
	db 10 ; size
	db 8, 16, 4, OAM_XFLIP | OAM_YFLIP
	db 0, 24, 5, OAM_XFLIP | OAM_YFLIP
	db 8, 24, 6, OAM_XFLIP | OAM_YFLIP
	db -16, 0, 0, $0
	db -16, 8, 1, $0
	db -8, 0, 2, $0
	db -8, 8, 0, $0
	db -8, 16, 1, $0
	db 0, 8, 2, $0
	db 0, 16, 3, $0

.data_ac989
	db 10 ; size
	db -8, 16, 6, OAM_XFLIP | OAM_YFLIP
	db -8, 8, 5, OAM_XFLIP | OAM_YFLIP
	db -16, 16, 4, OAM_XFLIP | OAM_YFLIP
	db 0, 16, 4, OAM_XFLIP | OAM_YFLIP
	db 0, 24, 6, OAM_XFLIP | OAM_YFLIP
	db 16, 16, 6, OAM_XFLIP | OAM_YFLIP
	db -24, 0, 0, $0
	db -24, 8, 1, $0
	db -16, 0, 2, $0
	db -16, 8, 3, $0

.data_ac9b2
	db 12 ; size
	db 16, -8, 6, OAM_XFLIP | OAM_YFLIP
	db -8, -24, 6, $0
	db 8, -8, 6, $0
	db 0, -24, 5, $0
	db 0, 16, 0, OAM_XFLIP
	db 0, 8, 1, OAM_XFLIP
	db 8, 16, 2, OAM_XFLIP
	db 8, 8, 0, OAM_XFLIP
	db 8, 0, 1, OAM_XFLIP
	db 16, 8, 2, OAM_XFLIP
	db 16, 0, 3, OAM_XFLIP
	db 8, -16, 4, $0

.data_ac9e3
	db 5 ; size
	db -8, 8, 6, $0
	db 8, 0, 5, $0
	db -16, -16, 4, $0
	db 0, -8, 6, $0
	db 0, -24, 4, $0

.data_ac9f8
	db 5 ; size
	db -8, 0, 6, $0
	db -16, -16, 5, $0
	db 8, 8, 6, $0
	db 0, -16, 6, $0
	db -16, 0, 6, $0

.data_aca0d
	db 2 ; size
	db -8, 16, 6, $0
	db 0, -8, 6, $0

AnimData108::
	frame_table AnimFrameTable36
	frame_data 0, 5, 0, 0
	frame_data 1, 5, 0, 0
	frame_data 2, 5, 0, 0
	frame_data 3, 6, 0, 0
	frame_data 4, 6, 0, 0
	frame_data 5, 5, 0, 0
	frame_data 6, 5, 0, 0
	frame_data 7, 6, 0, 0
	frame_data 8, 6, 0, 0
	frame_data 8, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable36::
	dw .data_aca57
	dw .data_aca5c
	dw .data_aca81
	dw .data_aca9a
	dw .data_acab3
	dw .data_acad0
	dw .data_acafd
	dw .data_acb16
	dw .data_acb33

.data_aca57
	db 1 ; size
	db -8, -16, 9, $0

.data_aca5c
	db 9 ; size
	db -16, -24, 0, $0
	db -16, -16, 1, $0
	db -16, -8, 2, $0
	db -8, -24, 3, $0
	db -8, -16, 4, $0
	db -8, -8, 5, $0
	db 0, -24, 6, $0
	db 0, -16, 7, $0
	db 0, -8, 8, $0

.data_aca81
	db 6 ; size
	db -24, -16, 9, $0
	db 0, -8, 9, $0
	db -16, -24, 9, $0
	db -16, -8, 10, $0
	db -8, -32, 10, $0
	db 8, -16, 10, $0

.data_aca9a
	db 6 ; size
	db -16, 0, 11, $0
	db 16, -16, 11, $0
	db -16, -32, 10, $0
	db -24, -16, 10, $0
	db 0, 0, 10, $0
	db 0, -32, 11, $0

.data_acab3
	db 7 ; size
	db 8, -36, 11, $0
	db -16, -12, 11, $0
	db -8, -36, 11, $0
	db 8, 4, 11, $0
	db 0, -20, 11, $0
	db 0, -4, 11, $0
	db -8, 8, 9, $0

.data_acad0
	db 11 ; size
	db -8, -24, 11, $0
	db 8, 0, 11, $0
	db -16, 0, 0, $0
	db -16, 8, 1, $0
	db -16, 16, 2, $0
	db -8, 0, 3, $0
	db -8, 8, 4, $0
	db -8, 16, 5, $0
	db 0, 0, 6, $0
	db 0, 8, 7, $0
	db 0, 16, 8, $0

.data_acafd
	db 6 ; size
	db -24, 8, 9, $0
	db 0, 16, 9, $0
	db -16, 0, 9, $0
	db -16, 16, 10, $0
	db -8, -8, 10, $0
	db 8, 8, 10, $0

.data_acb16
	db 7 ; size
	db 0, -16, 11, $0
	db -16, 24, 11, $0
	db 16, 8, 11, $0
	db -16, -8, 10, $0
	db -24, 8, 10, $0
	db 0, 24, 10, $0
	db -8, 16, 9, $0

.data_acb33
	db 6 ; size
	db 8, 28, 11, OAM_XFLIP
	db -16, 4, 11, OAM_XFLIP
	db -8, 28, 11, OAM_XFLIP
	db 8, -12, 11, OAM_XFLIP
	db 0, 12, 11, OAM_XFLIP
	db 0, -4, 11, OAM_XFLIP

AnimData109::
	frame_table AnimFrameTable37
	frame_data 0, 3, 0, 0
	frame_data 0, 3, 16, 0
	frame_data 0, 3, 16, 0
	frame_data 0, 3, 16, 0
	frame_data 1, 3, -48, 0
	frame_data 1, 3, 16, 0
	frame_data 1, 3, 16, 0
	frame_data 1, 3, 16, 0
	frame_data 2, 3, -48, 0
	frame_data 3, 3, 0, 0
	frame_data 4, 3, 0, 0
	frame_data 5, 3, 0, 0
	frame_data 6, 3, 0, 0
	frame_data 2, 3, 0, 0
	frame_data 3, 3, 0, 0
	frame_data 4, 3, 0, 0
	frame_data 5, 3, 0, 0
	frame_data 6, 3, 0, 0
	frame_data 2, 3, 0, 0
	frame_data 2, 3, 16, 0
	frame_data 7, 3, -16, 0
	frame_data 7, 3, 16, 0
	frame_data 7, 3, 16, 0
	frame_data 7, 3, 16, 0
	frame_data 8, 3, -48, 0
	frame_data 8, 3, 16, 0
	frame_data 8, 3, 16, 0
	frame_data 8, 3, 16, 0
	frame_data 8, 3, 16, 0
	frame_data 8, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable37::
	dw .data_acbdd
	dw .data_acc2e
	dw .data_accbf
	dw .data_acd60
	dw .data_ace01
	dw .data_acea2
	dw .data_acf43
	dw .data_acfe4
	dw .data_ad06d

.data_acbdd
	db 20 ; size
	db -72, -128, 0, $0
	db -72, -88, 0, $0
	db -62, -104, 0, $0
	db -62, -64, 0, $0
	db -52, -120, 0, $0
	db -52, -80, 0, $0
	db -42, -96, 0, $0
	db -32, -112, 0, $0
	db -32, -72, 0, $0
	db -42, -56, 0, $0
	db -22, -128, 0, $0
	db -22, -88, 0, $0
	db -12, -104, 0, $0
	db -12, -64, 0, $0
	db -2, -120, 0, $0
	db -2, -80, 0, $0
	db 8, -96, 0, $0
	db 18, -112, 0, $0
	db 18, -72, 0, $0
	db 8, -56, 0, $0

.data_acc2e
	db 36 ; size
	db -72, -104, 0, $0
	db -72, -64, 0, $0
	db -72, -24, 0, $0
	db -62, -120, 0, $0
	db -62, -80, 0, $0
	db -62, -40, 0, $0
	db -62, 0, 0, $0
	db -52, -96, 0, $0
	db -52, -56, 0, $0
	db -52, -16, 0, $0
	db -42, -112, 0, $0
	db -42, -72, 0, $0
	db -42, -32, 0, $0
	db -32, -128, 0, $0
	db -32, -88, 0, $0
	db -32, -48, 0, $0
	db -32, -8, 0, $0
	db -42, 8, 0, $0
	db -22, -104, 0, $0
	db -22, -64, 0, $0
	db -22, -24, 0, $0
	db -12, -120, 0, $0
	db -12, -80, 0, $0
	db -12, -40, 0, $0
	db -12, 0, 0, $0
	db -2, -96, 0, $0
	db -2, -56, 0, $0
	db -2, -16, 0, $0
	db 8, -112, 0, $0
	db 8, -72, 0, $0
	db 8, -32, 0, $0
	db 18, -128, 0, $0
	db 18, -88, 0, $0
	db 18, -48, 0, $0
	db 18, -8, 0, $0
	db 8, 8, 0, $0

.data_accbf
	db 40 ; size
	db -72, -80, 0, $0
	db -72, -40, 0, $0
	db -72, 0, 0, $0
	db -72, 40, 0, $0
	db -62, -56, 0, $0
	db -62, -16, 0, $0
	db -62, 24, 0, $0
	db -62, 64, 0, $0
	db -52, -72, 0, $0
	db -52, -32, 0, $0
	db -52, 8, 0, $0
	db -52, 48, 0, $0
	db -42, -48, 0, $0
	db -42, -8, 0, $0
	db -42, 32, 0, $0
	db -32, -64, 0, $0
	db -32, -24, 0, $0
	db -32, 16, 0, $0
	db -32, 56, 0, $0
	db -42, 72, 0, $0
	db -22, -80, 0, $0
	db -22, -40, 0, $0
	db -22, 0, 0, $0
	db -22, 40, 0, $0
	db -12, -56, 0, $0
	db -12, -16, 0, $0
	db -12, 24, 0, $0
	db -12, 64, 0, $0
	db -2, -72, 0, $0
	db -2, -32, 0, $0
	db -2, 8, 0, $0
	db -2, 48, 0, $0
	db 8, -48, 0, $0
	db 8, -8, 0, $0
	db 8, 32, 0, $0
	db 18, -64, 0, $0
	db 18, -24, 0, $0
	db 18, 16, 0, $0
	db 18, 56, 0, $0
	db 8, 72, 0, $0

.data_acd60
	db 40 ; size
	db -72, -64, 0, $0
	db -72, -24, 0, $0
	db -72, 16, 0, $0
	db -72, 56, 0, $0
	db -62, -40, 0, $0
	db -62, 0, 0, $0
	db -62, 40, 0, $0
	db -52, -56, 0, $0
	db -52, -16, 0, $0
	db -52, 24, 0, $0
	db -52, 64, 0, $0
	db -42, -32, 0, $0
	db -42, 8, 0, $0
	db -42, 48, 0, $0
	db -32, -48, 0, $0
	db -32, -8, 0, $0
	db -32, 32, 0, $0
	db -32, 72, 0, $0
	db -22, -64, 0, $0
	db -22, -24, 0, $0
	db -22, 16, 0, $0
	db -22, 56, 0, $0
	db -12, -40, 0, $0
	db -12, 0, 0, $0
	db -12, 40, 0, $0
	db -2, -56, 0, $0
	db -2, -16, 0, $0
	db -2, 24, 0, $0
	db -2, 64, 0, $0
	db 8, -32, 0, $0
	db 8, 8, 0, $0
	db 8, 48, 0, $0
	db 18, -48, 0, $0
	db 18, -8, 0, $0
	db 18, 32, 0, $0
	db 18, 72, 0, $0
	db -62, -80, 0, $0
	db -42, -72, 0, $0
	db -12, -80, 0, $0
	db 8, -72, 0, $0

.data_ace01
	db 40 ; size
	db -72, -48, 0, $0
	db -72, -8, 0, $0
	db -72, 32, 0, $0
	db -72, 72, 0, $0
	db -62, -24, 0, $0
	db -62, 16, 0, $0
	db -62, 56, 0, $0
	db -52, -40, 0, $0
	db -52, 0, 0, $0
	db -52, 40, 0, $0
	db -42, -16, 0, $0
	db -42, 24, 0, $0
	db -42, 64, 0, $0
	db -32, -32, 0, $0
	db -32, 8, 0, $0
	db -32, 48, 0, $0
	db -22, -48, 0, $0
	db -22, -8, 0, $0
	db -22, 32, 0, $0
	db -22, 72, 0, $0
	db -12, -24, 0, $0
	db -12, 16, 0, $0
	db -12, 56, 0, $0
	db -2, -40, 0, $0
	db -2, 0, 0, $0
	db -2, 40, 0, $0
	db 8, -16, 0, $0
	db 8, 24, 0, $0
	db 8, 64, 0, $0
	db 18, -32, 0, $0
	db 18, 8, 0, $0
	db 18, 48, 0, $0
	db -62, -64, 0, $0
	db -42, -56, 0, $0
	db -12, -64, 0, $0
	db 8, -56, 0, $0
	db -52, -80, 0, $0
	db -32, -72, 0, $0
	db -2, -80, 0, $0
	db 18, -72, 0, $0

.data_acea2
	db 40 ; size
	db -72, -32, 0, $0
	db -72, 8, 0, $0
	db -72, 48, 0, $0
	db -62, -8, 0, $0
	db -62, 32, 0, $0
	db -62, 72, 0, $0
	db -52, -24, 0, $0
	db -52, 16, 0, $0
	db -52, 56, 0, $0
	db -42, 0, 0, $0
	db -42, 40, 0, $0
	db -32, -16, 0, $0
	db -32, 24, 0, $0
	db -32, 64, 0, $0
	db -22, -32, 0, $0
	db -22, 8, 0, $0
	db -22, 48, 0, $0
	db -12, -8, 0, $0
	db -12, 32, 0, $0
	db -12, 72, 0, $0
	db -2, -24, 0, $0
	db -2, 16, 0, $0
	db -2, 56, 0, $0
	db 8, 0, 0, $0
	db 8, 40, 0, $0
	db 18, -16, 0, $0
	db 18, 24, 0, $0
	db 18, 64, 0, $0
	db -62, -48, 0, $0
	db -42, -40, 0, $0
	db -12, -48, 0, $0
	db 8, -40, 0, $0
	db -52, -64, 0, $0
	db -32, -56, 0, $0
	db -2, -64, 0, $0
	db 18, -56, 0, $0
	db -72, -72, 0, $0
	db -42, -80, 0, $0
	db -22, -72, 0, $0
	db 8, -80, 0, $0

.data_acf43
	db 40 ; size
	db -72, -16, 0, $0
	db -72, 24, 0, $0
	db -72, 64, 0, $0
	db -62, 8, 0, $0
	db -62, 48, 0, $0
	db -52, -8, 0, $0
	db -52, 32, 0, $0
	db -52, 72, 0, $0
	db -42, 16, 0, $0
	db -42, 56, 0, $0
	db -32, 0, 0, $0
	db -32, 40, 0, $0
	db -22, -16, 0, $0
	db -22, 24, 0, $0
	db -22, 64, 0, $0
	db -12, 8, 0, $0
	db -12, 48, 0, $0
	db -2, -8, 0, $0
	db -2, 32, 0, $0
	db -2, 72, 0, $0
	db 8, 16, 0, $0
	db 8, 56, 0, $0
	db 18, 0, 0, $0
	db 18, 40, 0, $0
	db -62, -32, 0, $0
	db -42, -24, 0, $0
	db -12, -32, 0, $0
	db 8, -24, 0, $0
	db -52, -48, 0, $0
	db -32, -40, 0, $0
	db -2, -48, 0, $0
	db 18, -40, 0, $0
	db -72, -56, 0, $0
	db -42, -64, 0, $0
	db -22, -56, 0, $0
	db 8, -64, 0, $0
	db -62, -72, 0, $0
	db -32, -80, 0, $0
	db -12, -72, 0, $0
	db 18, -80, 0, $0

.data_acfe4
	db 34 ; size
	db -72, -48, 0, $0
	db -72, -8, 0, $0
	db -62, -24, 0, $0
	db -62, 16, 0, $0
	db -52, -40, 0, $0
	db -52, 0, 0, $0
	db -42, -16, 0, $0
	db -42, 24, 0, $0
	db -32, -32, 0, $0
	db -32, 8, 0, $0
	db -22, -48, 0, $0
	db -22, -8, 0, $0
	db -12, -24, 0, $0
	db -12, 16, 0, $0
	db -2, -40, 0, $0
	db -2, 0, 0, $0
	db 8, -16, 0, $0
	db 8, 24, 0, $0
	db 18, -32, 0, $0
	db 18, 8, 0, $0
	db -8, -72, 0, $0
	db -48, -96, 0, $0
	db -72, 32, 0, $0
	db -72, 72, 0, $0
	db -62, 56, 0, $0
	db -52, 40, 0, $0
	db -42, 64, 0, $0
	db -32, 48, 0, $0
	db -22, 32, 0, $0
	db -22, 72, 0, $0
	db -12, 56, 0, $0
	db -2, 40, 0, $0
	db 8, 64, 0, $0
	db 18, 48, 0, $0

.data_ad06d
	db 18 ; size
	db -72, 16, 0, $0
	db -72, 56, 0, $0
	db -62, 40, 0, $0
	db -52, 24, 0, $0
	db -52, 64, 0, $0
	db -42, 48, 0, $0
	db -32, 32, 0, $0
	db -32, 72, 0, $0
	db -22, 16, 0, $0
	db -22, 56, 0, $0
	db -12, 40, 0, $0
	db -2, 24, 0, $0
	db -2, 64, 0, $0
	db 8, 48, 0, $0
	db 18, 32, 0, $0
	db 18, 72, 0, $0
	db -8, -8, 0, $0
	db -48, -32, 0, $0

AnimData110::
	frame_table AnimFrameTable38
	frame_data 0, 3, 0, 0
	frame_data 1, 3, 0, 0
	frame_data 2, 3, 0, 0
	frame_data 3, 3, 0, 0
	frame_data 4, 3, 0, 0
	frame_data 5, 3, 0, 0
	frame_data 6, 3, 0, 0
	frame_data 7, 3, 0, 0
	frame_data 8, 3, 0, 0
	frame_data 9, 3, 0, 0
	frame_data 10, 3, 0, 0
	frame_data 11, 3, 0, 0
	frame_data 12, 3, 0, 0
	frame_data 13, 3, 0, 0
	frame_data 14, 4, 0, 0
	frame_data 15, 5, 0, 0
	frame_data 16, 6, 0, 0
	frame_data 0, 3, 0, 0
	frame_data 1, 3, 0, 0
	frame_data 2, 3, 0, 0
	frame_data 3, 3, 0, 0
	frame_data 4, 3, 0, 0
	frame_data 5, 3, 0, 0
	frame_data 6, 3, 0, 0
	frame_data 7, 3, 0, 0
	frame_data 8, 3, 0, 0
	frame_data 9, 3, 0, 0
	frame_data 10, 3, 0, 0
	frame_data 11, 3, 0, 0
	frame_data 12, 3, 0, 0
	frame_data 13, 3, 0, 0
	frame_data 14, 5, 0, 0
	frame_data 15, 6, 0, 0
	frame_data 16, 7, 0, 0
	frame_data 16, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable38::
	dw .data_ad16b
	dw .data_ad17c
	dw .data_ad18d
	dw .data_ad19e
	dw .data_ad1af
	dw .data_ad1c0
	dw .data_ad1e1
	dw .data_ad212
	dw .data_ad243
	dw .data_ad274
	dw .data_ad295
	dw .data_ad2a6
	dw .data_ad2bf
	dw .data_ad2e0
	dw .data_ad301
	dw .data_ad322
	dw .data_ad343

.data_ad16b
	db 4 ; size
	db -26, -35, 0, $0
	db -26, 27, 0, OAM_XFLIP
	db 18, 27, 0, OAM_XFLIP | OAM_YFLIP
	db 18, -35, 0, OAM_YFLIP

.data_ad17c
	db 4 ; size
	db -25, -34, 0, $0
	db -25, 26, 0, OAM_XFLIP
	db 17, 26, 0, OAM_XFLIP | OAM_YFLIP
	db 17, -34, 0, OAM_YFLIP

.data_ad18d
	db 4 ; size
	db -24, -32, 1, $0
	db -24, 24, 1, OAM_XFLIP
	db 16, 24, 1, OAM_XFLIP | OAM_YFLIP
	db 16, -32, 1, OAM_YFLIP

.data_ad19e
	db 4 ; size
	db -23, -28, 2, $0
	db -23, 20, 2, OAM_XFLIP
	db 15, 20, 2, OAM_XFLIP | OAM_YFLIP
	db 15, -28, 2, OAM_YFLIP

.data_ad1af
	db 4 ; size
	db -20, -24, 3, $0
	db -20, 16, 3, OAM_XFLIP
	db 12, 16, 3, OAM_XFLIP | OAM_YFLIP
	db 12, -24, 3, OAM_YFLIP

.data_ad1c0
	db 8 ; size
	db -17, -21, 4, $0
	db -17, 13, 4, OAM_XFLIP
	db 9, 13, 4, OAM_XFLIP | OAM_YFLIP
	db 9, -21, 4, OAM_YFLIP
	db -17, -13, 5, $0
	db -17, 5, 5, OAM_XFLIP
	db 9, 5, 5, OAM_XFLIP | OAM_YFLIP
	db 9, -13, 5, OAM_YFLIP

.data_ad1e1
	db 12 ; size
	db -17, -24, 6, $0
	db -17, 16, 6, OAM_XFLIP
	db 9, 16, 6, OAM_XFLIP | OAM_YFLIP
	db 9, -24, 6, OAM_YFLIP
	db -17, -16, 7, $0
	db -17, 8, 7, OAM_XFLIP
	db 9, 8, 7, OAM_XFLIP | OAM_YFLIP
	db 9, -16, 7, OAM_YFLIP
	db -9, -16, 8, $0
	db -9, 8, 8, OAM_XFLIP
	db 1, 8, 8, OAM_XFLIP | OAM_YFLIP
	db 1, -16, 8, OAM_YFLIP

.data_ad212
	db 12 ; size
	db -16, -16, 9, $0
	db -16, 8, 9, OAM_XFLIP
	db 8, 8, 9, OAM_XFLIP | OAM_YFLIP
	db 8, -16, 9, OAM_YFLIP
	db -16, -8, 10, $0
	db -16, 0, 10, OAM_XFLIP
	db 8, 0, 10, OAM_XFLIP | OAM_YFLIP
	db 8, -8, 10, OAM_YFLIP
	db -8, -16, 11, $0
	db -8, 8, 11, OAM_XFLIP
	db 0, 8, 11, OAM_XFLIP | OAM_YFLIP
	db 0, -16, 11, OAM_YFLIP

.data_ad243
	db 12 ; size
	db -11, -12, 12, $0
	db -3, -10, 8, $0
	db -14, -4, 10, $0
	db -11, 4, 12, OAM_XFLIP
	db 3, 4, 12, OAM_XFLIP | OAM_YFLIP
	db 3, -12, 12, OAM_YFLIP
	db -14, -4, 10, OAM_XFLIP
	db 6, -4, 10, OAM_XFLIP | OAM_YFLIP
	db 6, -4, 10, OAM_YFLIP
	db -3, 2, 8, OAM_XFLIP
	db -5, 2, 8, OAM_XFLIP | OAM_YFLIP
	db -5, -10, 8, OAM_YFLIP

.data_ad274
	db 8 ; size
	db -16, -4, 13, $0
	db 8, -4, 13, OAM_YFLIP
	db -4, -16, 14, $0
	db -4, 8, 14, OAM_XFLIP
	db -8, -8, 15, $0
	db -8, 0, 15, OAM_XFLIP
	db 0, 0, 15, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 15, OAM_YFLIP

.data_ad295
	db 4 ; size
	db -8, -8, 16, $0
	db -8, 0, 16, OAM_XFLIP
	db 0, 0, 16, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 16, OAM_YFLIP

.data_ad2a6
	db 6 ; size
	db -8, -12, 17, $0
	db -8, 4, 17, OAM_XFLIP
	db 0, 4, 17, OAM_XFLIP | OAM_YFLIP
	db 0, -12, 17, OAM_YFLIP
	db -8, -4, 18, $0
	db 0, -4, 18, OAM_XFLIP | OAM_YFLIP

.data_ad2bf
	db 8 ; size
	db -16, -4, 19, $0
	db 8, -4, 19, OAM_YFLIP
	db -4, -16, 20, $0
	db -4, 8, 20, OAM_XFLIP
	db -8, -8, 21, $0
	db -8, 0, 21, OAM_XFLIP
	db 0, 0, 21, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 21, OAM_YFLIP

.data_ad2e0
	db 8 ; size
	db -16, -4, 22, $0
	db 8, -4, 22, OAM_YFLIP
	db -4, -16, 23, $0
	db -4, 8, 23, OAM_XFLIP
	db -8, -8, 24, $0
	db -8, 0, 24, OAM_XFLIP
	db 0, 0, 24, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 24, OAM_YFLIP

.data_ad301
	db 8 ; size
	db -16, -4, 25, $0
	db 8, -4, 25, OAM_YFLIP
	db -4, -16, 26, $0
	db -4, 8, 26, OAM_XFLIP
	db -8, -8, 27, $0
	db -8, 0, 27, OAM_XFLIP
	db 0, 0, 27, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 27, OAM_YFLIP

.data_ad322
	db 8 ; size
	db -16, -4, 28, $0
	db 8, -4, 28, OAM_YFLIP
	db -4, -16, 29, $0
	db -4, 8, 29, OAM_XFLIP
	db -8, -8, 30, $0
	db -8, 0, 30, OAM_XFLIP
	db 0, 0, 30, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 30, OAM_YFLIP

.data_ad343
	db 8 ; size
	db -16, -4, 31, $0
	db 8, -4, 31, OAM_YFLIP
	db -4, -16, 32, $0
	db -4, 8, 32, OAM_XFLIP
	db -8, -8, 33, $0
	db -8, 0, 33, OAM_XFLIP
	db 0, 0, 33, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 33, OAM_YFLIP

AnimData111::
	frame_table AnimFrameTable39
	frame_data 0, 6, 0, 0
	frame_data 1, 6, 0, 0
	frame_data 2, 6, 0, 0
	frame_data 3, 6, 0, 0
	frame_data 4, 10, 0, 0
	frame_data 5, 16, 0, 0
	frame_data 5, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable39::
	dw .data_ad393
	dw .data_ad3bc
	dw .data_ad3e5
	dw .data_ad40e
	dw .data_ad43f
	dw .data_ad480

.data_ad393
	db 10 ; size
	db -13, 16, 0, $0
	db -5, 8, 1, $0
	db -5, 16, 2, $0
	db 3, 0, 3, $0
	db 3, 8, 4, $0
	db -13, -24, 0, OAM_XFLIP
	db -5, -16, 1, OAM_XFLIP
	db -5, -24, 2, OAM_XFLIP
	db 3, -8, 3, OAM_XFLIP
	db 3, -16, 4, OAM_XFLIP

.data_ad3bc
	db 10 ; size
	db -13, 16, 0, $0
	db -5, 8, 5, $0
	db -5, 16, 6, $0
	db 3, 8, 7, $0
	db 3, 0, 3, $0
	db -13, -24, 0, OAM_XFLIP
	db -5, -16, 5, OAM_XFLIP
	db -5, -24, 6, OAM_XFLIP
	db 3, -16, 7, OAM_XFLIP
	db 3, -8, 3, OAM_XFLIP

.data_ad3e5
	db 10 ; size
	db -12, 16, 8, $0
	db -4, 8, 9, $0
	db -4, 16, 10, $0
	db 4, 1, 11, $0
	db 4, 9, 12, $0
	db -12, -24, 8, OAM_XFLIP
	db -4, -16, 9, OAM_XFLIP
	db -4, -24, 10, OAM_XFLIP
	db 4, -9, 11, OAM_XFLIP
	db 4, -17, 12, OAM_XFLIP

.data_ad40e
	db 12 ; size
	db -13, 16, 13, $0
	db -5, 8, 14, $0
	db -5, 16, 15, $0
	db 3, 2, 16, $0
	db 3, 10, 17, $0
	db 3, 18, 18, $0
	db -13, -24, 13, OAM_XFLIP
	db -5, -16, 14, OAM_XFLIP
	db -5, -24, 15, OAM_XFLIP
	db 3, -10, 16, OAM_XFLIP
	db 3, -18, 17, OAM_XFLIP
	db 3, -26, 18, OAM_XFLIP

.data_ad43f
	db 16 ; size
	db -12, 16, 19, $0
	db -4, 8, 20, $0
	db -4, 16, 21, $0
	db 4, 0, 22, $0
	db 4, 8, 23, $0
	db 4, 16, 24, $0
	db -4, 0, 18, OAM_XFLIP | OAM_YFLIP
	db -12, 8, 18, OAM_XFLIP | OAM_YFLIP
	db -12, -24, 19, OAM_XFLIP
	db -4, -16, 20, OAM_XFLIP
	db -4, -24, 21, OAM_XFLIP
	db 4, -8, 22, OAM_XFLIP
	db 4, -16, 23, OAM_XFLIP
	db 4, -24, 24, OAM_XFLIP
	db -4, -8, 18, OAM_YFLIP
	db -12, -16, 18, OAM_YFLIP

.data_ad480
	db 16 ; size
	db -12, 16, 25, $0
	db -4, 0, 26, $0
	db -4, 8, 27, $0
	db -4, 16, 28, $0
	db 4, 0, 29, $0
	db 4, 8, 30, $0
	db 4, 16, 31, $0
	db -12, 8, 18, OAM_XFLIP | OAM_YFLIP
	db -12, -24, 25, OAM_XFLIP
	db -4, -8, 26, OAM_XFLIP
	db -4, -16, 27, OAM_XFLIP
	db -4, -24, 28, OAM_XFLIP
	db 4, -8, 29, OAM_XFLIP
	db 4, -16, 30, OAM_XFLIP
	db 4, -24, 31, OAM_XFLIP
	db -12, -16, 18, OAM_YFLIP

AnimData112::
	frame_table AnimFrameTable40
	frame_data 0, 2, 0, 0
	frame_data 1, 4, 0, 0
	frame_data 2, 4, 0, 0
	frame_data 1, 4, 0, 0
	frame_data 2, 4, 0, 0
	frame_data 3, 4, 0, 0
	frame_data 4, 4, 0, 0
	frame_data 5, 2, 0, 0
	frame_data 6, 2, 0, 0
	frame_data 7, 2, 0, 0
	frame_data 8, 2, 0, 0
	frame_data 9, 2, 0, 0
	frame_data 10, 2, 0, 0
	frame_data 10, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable40::
	dw .data_ad516
	dw .data_ad537
	dw .data_ad580
	dw .data_ad5c9
	dw .data_ad612
	dw .data_ad65b
	dw .data_ad6a4
	dw .data_ad6ed
	dw .data_ad73a
	dw .data_ad787
	dw .data_ad7d8

.data_ad516
	db 8 ; size
	db -64, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -56, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -48, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -40, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -40, -8, 0, $0
	db -48, -8, 0, $0
	db -56, -8, 0, $0
	db -64, -8, 0, $0

.data_ad537
	db 18 ; size
	db -64, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -56, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -48, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -40, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -32, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -24, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -16, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -8, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -8, -8, 0, $0
	db -16, -8, 0, $0
	db -24, -8, 0, $0
	db -32, -8, 0, $0
	db -40, -8, 0, $0
	db -48, -8, 0, $0
	db -56, -8, 0, $0
	db -64, -8, 0, $0
	db 0, -8, 1, OAM_YFLIP
	db 0, 0, 1, OAM_XFLIP | OAM_YFLIP

.data_ad580
	db 18 ; size
	db -64, -8, 0, OAM_YFLIP
	db -56, -8, 0, OAM_YFLIP
	db -48, -8, 0, OAM_YFLIP
	db -40, -8, 0, OAM_YFLIP
	db -32, -8, 0, OAM_YFLIP
	db -24, -8, 0, OAM_YFLIP
	db -16, -8, 0, OAM_YFLIP
	db -8, -8, 0, OAM_YFLIP
	db -8, 0, 0, OAM_XFLIP
	db -16, 0, 0, OAM_XFLIP
	db -24, 0, 0, OAM_XFLIP
	db -32, 0, 0, OAM_XFLIP
	db -40, 0, 0, OAM_XFLIP
	db -48, 0, 0, OAM_XFLIP
	db -56, 0, 0, OAM_XFLIP
	db -64, 0, 0, OAM_XFLIP
	db 0, 0, 1, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 1, OAM_YFLIP

.data_ad5c9
	db 18 ; size
	db -8, 0, 2, OAM_XFLIP | OAM_YFLIP
	db -16, 0, 2, OAM_XFLIP | OAM_YFLIP
	db -24, 0, 2, OAM_XFLIP | OAM_YFLIP
	db -32, 0, 2, OAM_XFLIP | OAM_YFLIP
	db -40, 0, 2, OAM_XFLIP | OAM_YFLIP
	db -48, 0, 2, OAM_XFLIP | OAM_YFLIP
	db -56, 0, 2, OAM_XFLIP | OAM_YFLIP
	db -64, 0, 2, OAM_XFLIP | OAM_YFLIP
	db 0, 0, 3, OAM_XFLIP | OAM_YFLIP
	db -64, -8, 2, $0
	db -56, -8, 2, $0
	db -48, -8, 2, $0
	db -40, -8, 2, $0
	db -32, -8, 2, $0
	db -24, -8, 2, $0
	db -16, -8, 2, $0
	db -8, -8, 2, $0
	db 0, -8, 3, OAM_YFLIP

.data_ad612
	db 18 ; size
	db -8, -8, 2, OAM_YFLIP
	db -16, -8, 2, OAM_YFLIP
	db -24, -8, 2, OAM_YFLIP
	db -32, -8, 2, OAM_YFLIP
	db -40, -8, 2, OAM_YFLIP
	db -48, -8, 2, OAM_YFLIP
	db -56, -8, 2, OAM_YFLIP
	db -64, -8, 2, OAM_YFLIP
	db 0, 0, 3, OAM_XFLIP | OAM_YFLIP
	db -64, 0, 2, OAM_XFLIP
	db -56, 0, 2, OAM_XFLIP
	db -48, 0, 2, OAM_XFLIP
	db -40, 0, 2, OAM_XFLIP
	db -32, 0, 2, OAM_XFLIP
	db -24, 0, 2, OAM_XFLIP
	db -16, 0, 2, OAM_XFLIP
	db -8, 0, 2, OAM_XFLIP
	db 0, -8, 3, OAM_YFLIP

.data_ad65b
	db 18 ; size
	db -8, 0, 4, OAM_XFLIP | OAM_YFLIP
	db -16, 0, 4, OAM_XFLIP | OAM_YFLIP
	db -24, 0, 4, OAM_XFLIP | OAM_YFLIP
	db -32, 0, 4, OAM_XFLIP | OAM_YFLIP
	db -40, 0, 4, OAM_XFLIP | OAM_YFLIP
	db -48, 0, 4, OAM_XFLIP | OAM_YFLIP
	db -56, 0, 4, OAM_XFLIP | OAM_YFLIP
	db -64, 0, 4, OAM_XFLIP | OAM_YFLIP
	db 0, 0, 5, OAM_XFLIP | OAM_YFLIP
	db -64, -8, 4, $0
	db -56, -8, 4, $0
	db -48, -8, 4, $0
	db -40, -8, 4, $0
	db -32, -8, 4, $0
	db -24, -8, 4, $0
	db -16, -8, 4, $0
	db -8, -8, 4, $0
	db 0, -8, 5, OAM_YFLIP

.data_ad6a4
	db 18 ; size
	db -8, -8, 4, OAM_YFLIP
	db -16, -8, 4, OAM_YFLIP
	db -24, -8, 4, OAM_YFLIP
	db -32, -8, 4, OAM_YFLIP
	db -40, -8, 4, OAM_YFLIP
	db -48, -8, 4, OAM_YFLIP
	db -56, -8, 4, OAM_YFLIP
	db -64, -8, 4, OAM_YFLIP
	db 0, 0, 5, OAM_XFLIP | OAM_YFLIP
	db -64, 0, 4, OAM_XFLIP
	db -56, 0, 4, OAM_XFLIP
	db -48, 0, 4, OAM_XFLIP
	db -40, 0, 4, OAM_XFLIP
	db -32, 0, 4, OAM_XFLIP
	db -24, 0, 4, OAM_XFLIP
	db -16, 0, 4, OAM_XFLIP
	db -8, 0, 4, OAM_XFLIP
	db 0, -8, 5, OAM_YFLIP

.data_ad6ed
	db 19 ; size
	db -8, 4, 4, OAM_XFLIP | OAM_YFLIP
	db -16, 4, 4, OAM_XFLIP | OAM_YFLIP
	db -24, 4, 4, OAM_XFLIP | OAM_YFLIP
	db -32, 4, 4, OAM_XFLIP | OAM_YFLIP
	db -40, 4, 4, OAM_XFLIP | OAM_YFLIP
	db -48, 4, 4, OAM_XFLIP | OAM_YFLIP
	db -56, 4, 4, OAM_XFLIP | OAM_YFLIP
	db -64, 4, 4, OAM_XFLIP | OAM_YFLIP
	db 0, 4, 5, OAM_XFLIP | OAM_YFLIP
	db -64, -12, 4, $0
	db -56, -12, 4, $0
	db -48, -12, 4, $0
	db -40, -12, 4, $0
	db -32, -12, 4, $0
	db -24, -12, 4, $0
	db -16, -12, 4, $0
	db -8, -12, 4, $0
	db 0, -12, 5, OAM_YFLIP
	db 0, -4, 6, OAM_YFLIP

.data_ad73a
	db 19 ; size
	db -8, -12, 4, OAM_YFLIP
	db -16, -12, 4, OAM_YFLIP
	db -24, -12, 4, OAM_YFLIP
	db -32, -12, 4, OAM_YFLIP
	db -40, -12, 4, OAM_YFLIP
	db -48, -12, 4, OAM_YFLIP
	db -56, -12, 4, OAM_YFLIP
	db -64, -12, 4, OAM_YFLIP
	db 0, 4, 5, OAM_XFLIP | OAM_YFLIP
	db -64, 4, 4, OAM_XFLIP
	db -56, 4, 4, OAM_XFLIP
	db -48, 4, 4, OAM_XFLIP
	db -40, 4, 4, OAM_XFLIP
	db -32, 4, 4, OAM_XFLIP
	db -24, 4, 4, OAM_XFLIP
	db -16, 4, 4, OAM_XFLIP
	db -8, 4, 4, OAM_XFLIP
	db 0, -12, 5, OAM_YFLIP
	db 0, -4, 6, OAM_YFLIP

.data_ad787
	db 20 ; size
	db -8, 8, 7, OAM_XFLIP | OAM_YFLIP
	db -16, 8, 7, OAM_XFLIP | OAM_YFLIP
	db -24, 8, 7, OAM_XFLIP | OAM_YFLIP
	db -32, 8, 7, OAM_XFLIP | OAM_YFLIP
	db -40, 8, 7, OAM_XFLIP | OAM_YFLIP
	db -48, 8, 7, OAM_XFLIP | OAM_YFLIP
	db -56, 8, 7, OAM_XFLIP | OAM_YFLIP
	db -64, 8, 7, OAM_XFLIP | OAM_YFLIP
	db 0, 8, 8, OAM_XFLIP | OAM_YFLIP
	db 0, 0, 9, OAM_XFLIP | OAM_YFLIP
	db -64, -16, 7, $0
	db -56, -16, 7, $0
	db -48, -16, 7, $0
	db -40, -16, 7, $0
	db -32, -16, 7, $0
	db -24, -16, 7, $0
	db -16, -16, 7, $0
	db -8, -16, 7, $0
	db 0, -16, 8, OAM_YFLIP
	db 0, -8, 9, OAM_YFLIP

.data_ad7d8
	db 20 ; size
	db -64, 8, 7, OAM_XFLIP
	db -56, 8, 7, OAM_XFLIP
	db -48, 8, 7, OAM_XFLIP
	db -40, 8, 7, OAM_XFLIP
	db -32, 8, 7, OAM_XFLIP
	db -24, 8, 7, OAM_XFLIP
	db -16, 8, 7, OAM_XFLIP
	db -8, 8, 7, OAM_XFLIP
	db 0, 8, 8, OAM_XFLIP | OAM_YFLIP
	db 0, 0, 9, OAM_XFLIP | OAM_YFLIP
	db -8, -16, 7, OAM_YFLIP
	db -16, -16, 7, OAM_YFLIP
	db -24, -16, 7, OAM_YFLIP
	db -32, -16, 7, OAM_YFLIP
	db -40, -16, 7, OAM_YFLIP
	db -48, -16, 7, OAM_YFLIP
	db -56, -16, 7, OAM_YFLIP
	db -64, -16, 7, OAM_YFLIP
	db 0, -16, 8, OAM_YFLIP
	db 0, -8, 9, OAM_YFLIP

AnimData113::
	frame_table AnimFrameTable41
	frame_data 0, 2, 0, 0
	frame_data 1, 2, 0, 0
	frame_data 2, 2, 0, 0
	frame_data 3, 2, 0, 0
	frame_data 4, 2, 0, 0
	frame_data 5, 2, 0, 0
	frame_data 6, 2, 0, 0
	frame_data 7, 2, 0, 0
	frame_data 8, 2, 0, 0
	frame_data 9, 2, 0, 0
	frame_data 10, 4, 0, 0
	frame_data 11, 6, 0, 0
	frame_data 12, 6, 0, 0
	frame_data 11, 8, 0, 0
	frame_data 12, 8, 0, 0
	frame_data -1, 16, 0, 0
	frame_data -1, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable41::
	dw .data_ad88e
	dw .data_ad8af
	dw .data_ad8dc
	dw .data_ad915
	dw .data_ad942
	dw .data_ad96f
	dw .data_ad998
	dw .data_ad9bd
	dw .data_ad9f2
	dw .data_ada23
	dw .data_ada50
	dw .data_ada79
	dw .data_adab2

.data_ad88e
	db 8 ; size
	db -64, -12, 5, OAM_YFLIP
	db -64, -4, 6, OAM_YFLIP
	db -64, 4, 7, OAM_YFLIP
	db -56, -12, 2, OAM_YFLIP
	db -56, -4, 3, OAM_YFLIP
	db -56, 4, 4, OAM_YFLIP
	db -48, -8, 0, OAM_YFLIP
	db -48, 0, 1, OAM_YFLIP

.data_ad8af
	db 11 ; size
	db -56, -4, 8, OAM_XFLIP | OAM_YFLIP
	db -64, -4, 8, OAM_XFLIP | OAM_YFLIP
	db -48, -4, 8, OAM_XFLIP | OAM_YFLIP
	db -40, 4, 5, OAM_XFLIP | OAM_YFLIP
	db -40, -4, 6, OAM_XFLIP | OAM_YFLIP
	db -40, -12, 7, OAM_XFLIP | OAM_YFLIP
	db -32, 4, 2, OAM_XFLIP | OAM_YFLIP
	db -32, -4, 3, OAM_XFLIP | OAM_YFLIP
	db -32, -12, 4, OAM_XFLIP | OAM_YFLIP
	db -24, 0, 0, OAM_XFLIP | OAM_YFLIP
	db -24, -8, 1, OAM_XFLIP | OAM_YFLIP

.data_ad8dc
	db 14 ; size
	db -32, -4, 8, OAM_YFLIP
	db -40, -4, 8, OAM_YFLIP
	db -48, -4, 8, OAM_YFLIP
	db -56, -4, 8, OAM_YFLIP
	db -24, -4, 8, OAM_YFLIP
	db -16, -12, 5, OAM_YFLIP
	db -16, -4, 6, OAM_YFLIP
	db -16, 4, 7, OAM_YFLIP
	db -8, -12, 2, OAM_YFLIP
	db -8, -4, 3, OAM_YFLIP
	db -8, 4, 4, OAM_YFLIP
	db 0, -8, 0, OAM_YFLIP
	db 0, 0, 1, OAM_YFLIP
	db -64, -4, 9, OAM_XFLIP | OAM_YFLIP

.data_ad915
	db 11 ; size
	db 0, -8, 10, OAM_YFLIP
	db 0, 0, 11, OAM_YFLIP
	db -8, -8, 12, OAM_YFLIP
	db -8, 0, 13, OAM_YFLIP
	db -16, -4, 8, $0
	db -24, -4, 8, $0
	db -32, -4, 8, $0
	db -40, -4, 8, $0
	db -48, -4, 8, $0
	db -56, -4, 9, OAM_XFLIP | OAM_YFLIP
	db -64, -4, 9, $0

.data_ad942
	db 11 ; size
	db 0, 0, 10, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 11, OAM_XFLIP | OAM_YFLIP
	db -8, 0, 12, OAM_XFLIP | OAM_YFLIP
	db -8, -8, 13, OAM_XFLIP | OAM_YFLIP
	db -16, -4, 8, $0
	db -24, -4, 8, $0
	db -48, -4, 9, OAM_XFLIP | OAM_YFLIP
	db -56, -4, 9, $0
	db -32, -4, 8, $0
	db -40, -4, 8, $0
	db -64, -4, 8, $0

.data_ad96f
	db 10 ; size
	db 0, -8, 10, OAM_YFLIP
	db 0, 0, 11, OAM_YFLIP
	db -8, -8, 12, OAM_YFLIP
	db -8, 0, 13, OAM_YFLIP
	db -40, -4, 9, OAM_XFLIP | OAM_YFLIP
	db -48, -4, 9, $0
	db -16, -4, 8, $0
	db -24, -4, 8, $0
	db -32, -4, 8, $0
	db -56, -4, 8, $0

.data_ad998
	db 9 ; size
	db 0, 0, 10, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 11, OAM_XFLIP | OAM_YFLIP
	db -8, 0, 12, OAM_XFLIP | OAM_YFLIP
	db -8, -8, 13, OAM_XFLIP | OAM_YFLIP
	db -16, -4, 8, $0
	db -24, -4, 8, $0
	db -32, -4, 9, OAM_XFLIP | OAM_YFLIP
	db -40, -4, 9, $0
	db -48, -4, 8, $0

.data_ad9bd
	db 13 ; size
	db -24, -4, 9, OAM_XFLIP | OAM_YFLIP
	db -32, -4, 9, $0
	db -16, -4, 8, $0
	db -40, -4, 8, $0
	db 8, -12, 14, OAM_YFLIP
	db 8, -4, 15, OAM_YFLIP
	db 8, 4, 16, OAM_YFLIP
	db 0, -12, 17, OAM_YFLIP
	db 0, -4, 18, OAM_YFLIP
	db 0, 4, 19, OAM_YFLIP
	db -8, -12, 20, OAM_YFLIP
	db -8, -4, 21, OAM_YFLIP
	db -8, 4, 22, OAM_YFLIP

.data_ad9f2
	db 12 ; size
	db -32, -4, 8, $0
	db -16, -4, 9, OAM_XFLIP | OAM_YFLIP
	db -24, -4, 9, $0
	db 8, 4, 14, OAM_XFLIP | OAM_YFLIP
	db 8, -4, 15, OAM_XFLIP | OAM_YFLIP
	db 8, -12, 16, OAM_XFLIP | OAM_YFLIP
	db 0, 4, 17, OAM_XFLIP | OAM_YFLIP
	db 0, -4, 18, OAM_XFLIP | OAM_YFLIP
	db 0, -12, 19, OAM_XFLIP | OAM_YFLIP
	db -8, 4, 20, OAM_XFLIP | OAM_YFLIP
	db -8, -4, 21, OAM_XFLIP | OAM_YFLIP
	db -8, -12, 22, OAM_XFLIP | OAM_YFLIP

.data_ada23
	db 11 ; size
	db -24, -4, 8, $0
	db -16, -4, 9, $0
	db 8, -12, 14, OAM_YFLIP
	db 8, -4, 15, OAM_YFLIP
	db 8, 4, 16, OAM_YFLIP
	db 0, -12, 17, OAM_YFLIP
	db 0, -4, 18, OAM_YFLIP
	db 0, 4, 19, OAM_YFLIP
	db -8, -12, 20, OAM_YFLIP
	db -8, -4, 21, OAM_YFLIP
	db -8, 4, 22, OAM_YFLIP

.data_ada50
	db 10 ; size
	db -16, -4, 8, $0
	db 8, 4, 14, OAM_XFLIP | OAM_YFLIP
	db 8, -4, 15, OAM_XFLIP | OAM_YFLIP
	db 8, -12, 16, OAM_XFLIP | OAM_YFLIP
	db 0, 4, 17, OAM_XFLIP | OAM_YFLIP
	db 0, -4, 18, OAM_XFLIP | OAM_YFLIP
	db 0, -12, 19, OAM_XFLIP | OAM_YFLIP
	db -8, 4, 20, OAM_XFLIP | OAM_YFLIP
	db -8, -4, 21, OAM_XFLIP | OAM_YFLIP
	db -8, -12, 22, OAM_XFLIP | OAM_YFLIP

.data_ada79
	db 14 ; size
	db -16, -8, 35, OAM_YFLIP
	db -16, 0, 36, OAM_YFLIP
	db -8, -16, 31, OAM_YFLIP
	db -8, -8, 32, OAM_YFLIP
	db -8, 0, 33, OAM_YFLIP
	db -8, 8, 34, OAM_YFLIP
	db 0, -16, 27, OAM_YFLIP
	db 0, -8, 28, OAM_YFLIP
	db 0, 0, 29, OAM_YFLIP
	db 0, 8, 30, OAM_YFLIP
	db 8, -16, 23, OAM_YFLIP
	db 8, -8, 24, OAM_YFLIP
	db 8, 0, 25, OAM_YFLIP
	db 8, 8, 26, OAM_YFLIP

.data_adab2
	db 14 ; size
	db 12, 0, 35, OAM_XFLIP
	db 12, -8, 36, OAM_XFLIP
	db 4, 8, 31, OAM_XFLIP
	db 4, 0, 32, OAM_XFLIP
	db 4, -8, 33, OAM_XFLIP
	db 4, -16, 34, OAM_XFLIP
	db -4, 8, 27, OAM_XFLIP
	db -4, 0, 28, OAM_XFLIP
	db -4, -8, 29, OAM_XFLIP
	db -4, -16, 30, OAM_XFLIP
	db -12, 8, 23, OAM_XFLIP
	db -12, 0, 24, OAM_XFLIP
	db -12, -8, 25, OAM_XFLIP
	db -12, -16, 26, OAM_XFLIP

AnimData114::
	frame_table AnimFrameTable42
	frame_data 0, 11, 0, 0
	frame_data 1, 11, 0, 0
	frame_data 2, 11, 0, 0
	frame_data 0, 11, -24, 24
	frame_data 1, 11, 0, 0
	frame_data 2, 11, 0, 0
	frame_data 0, 11, -24, 24
	frame_data 0, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable42::
	dw .data_adb2c
	dw .data_adb55
	dw .data_adb7e
	dw .data_adba7
	dw .data_adbe4
	dw .data_adc4d
	dw .data_adc8e
	dw .data_adce3
	dw .data_add24
	dw .data_add65
	dw .data_add7e
	dw .data_add97
	dw .data_addb0

.data_adb2c
	db 10 ; size
	db -24, 16, 2, $0
	db -24, 24, 3, $0
	db -32, 16, 0, $0
	db -32, 24, 1, $0
	db -16, 22, 21, $0
	db -28, 32, 22, $0
	db -25, 8, 20, $0
	db -33, 8, 20, OAM_YFLIP
	db -32, 32, 14, $0
	db -24, 32, 15, $0

.data_adb55
	db 10 ; size
	db -24, 8, 4, $0
	db -24, 16, 5, $0
	db -16, 8, 6, $0
	db -16, 16, 7, $0
	db -21, 24, 22, $0
	db -24, 24, 12, $0
	db -16, 24, 13, $0
	db -15, 0, 20, $0
	db -32, 16, 23, $0
	db -8, 8, 23, OAM_XFLIP | OAM_YFLIP

.data_adb7e
	db 10 ; size
	db -8, 8, 0, OAM_XFLIP | OAM_YFLIP
	db -8, 0, 1, OAM_XFLIP | OAM_YFLIP
	db -16, 8, 2, OAM_XFLIP | OAM_YFLIP
	db -16, 0, 3, OAM_XFLIP | OAM_YFLIP
	db -13, -8, 22, OAM_XFLIP
	db -24, 5, 21, OAM_YFLIP
	db -7, 16, 20, OAM_XFLIP
	db -15, 16, 20, OAM_XFLIP | OAM_YFLIP
	db -16, 16, 14, $0
	db -8, 16, 15, $0

.data_adba7
	db 15 ; size
	db -24, -16, 18, $0
	db -24, -8, 19, $0
	db -24, 0, 13, $0
	db 16, -16, 0, OAM_XFLIP | OAM_YFLIP
	db 16, -24, 1, OAM_XFLIP | OAM_YFLIP
	db 8, -16, 2, OAM_XFLIP | OAM_YFLIP
	db 8, -24, 3, OAM_XFLIP | OAM_YFLIP
	db 11, -32, 22, OAM_XFLIP
	db 0, -19, 21, OAM_YFLIP
	db 17, -8, 20, OAM_XFLIP
	db 9, -8, 20, OAM_XFLIP | OAM_YFLIP
	db 8, -8, 14, $0
	db 16, -8, 15, $0
	db -32, -16, 16, $0
	db -32, -8, 17, $0

.data_adbe4
	db 26 ; size
	db -24, -11, 14, $0
	db -16, -8, 15, $0
	db -24, -24, 8, $0
	db -24, -16, 9, $0
	db -16, -24, 10, $0
	db -16, -16, 11, $0
	db 24, -32, 2, $0
	db 24, -24, 3, $0
	db 16, -32, 0, $0
	db 16, -24, 1, $0
	db 32, -26, 21, $0
	db 20, -16, 22, $0
	db 23, -40, 20, $0
	db 15, -40, 20, OAM_YFLIP
	db 16, -16, 14, $0
	db 24, -16, 15, $0
	db -8, 24, 2, $0
	db -8, 32, 3, $0
	db -16, 24, 0, $0
	db -16, 32, 1, $0
	db 0, 30, 21, $0
	db -12, 40, 22, $0
	db -9, 16, 20, $0
	db -17, 16, 20, OAM_YFLIP
	db -16, 40, 14, $0
	db -8, 40, 15, $0

.data_adc4d
	db 16 ; size
	db -18, -18, 12, $0
	db -10, -18, 13, $0
	db -8, -24, 16, OAM_XFLIP | OAM_YFLIP
	db -8, -32, 17, OAM_XFLIP | OAM_YFLIP
	db -16, -24, 18, OAM_XFLIP | OAM_YFLIP
	db -16, -32, 19, OAM_XFLIP | OAM_YFLIP
	db -8, 16, 4, $0
	db -8, 24, 5, $0
	db 0, 16, 6, $0
	db 0, 24, 7, $0
	db -5, 32, 22, $0
	db -8, 32, 12, $0
	db 0, 32, 13, $0
	db 1, 8, 20, $0
	db -16, 24, 23, $0
	db 8, 16, 23, OAM_XFLIP | OAM_YFLIP

.data_adc8e
	db 21 ; size
	db -10, -28, 14, $0
	db -2, -26, 15, $0
	db -24, 8, 18, $0
	db -24, 16, 19, $0
	db -24, 22, 15, $0
	db 0, -32, 8, OAM_XFLIP | OAM_YFLIP
	db -8, -32, 10, OAM_XFLIP | OAM_YFLIP
	db 8, 16, 0, OAM_XFLIP | OAM_YFLIP
	db 8, 8, 1, OAM_XFLIP | OAM_YFLIP
	db 0, 16, 2, OAM_XFLIP | OAM_YFLIP
	db 0, 8, 3, OAM_XFLIP | OAM_YFLIP
	db 3, 0, 22, OAM_XFLIP
	db -8, 13, 21, OAM_YFLIP
	db 9, 24, 20, OAM_XFLIP
	db 1, 24, 20, OAM_XFLIP | OAM_YFLIP
	db 0, 24, 14, $0
	db 8, 24, 15, $0
	db -8, -40, 8, $0
	db 0, -40, 10, $0
	db -32, 8, 16, $0
	db -32, 16, 17, $0

.data_adce3
	db 16 ; size
	db -24, 14, 14, $0
	db -16, 14, 15, $0
	db -24, 0, 8, $0
	db -24, 8, 9, $0
	db -16, 0, 10, $0
	db -16, 8, 11, $0
	db 16, 0, 2, $0
	db 16, 8, 3, $0
	db 8, 0, 0, $0
	db 8, 8, 1, $0
	db 24, 6, 21, $0
	db 12, 16, 22, $0
	db 15, -8, 20, $0
	db 7, -8, 20, OAM_YFLIP
	db 8, 16, 14, $0
	db 16, 16, 15, $0

.data_add24
	db 16 ; size
	db -18, 4, 12, $0
	db -10, 6, 13, $0
	db -8, 0, 16, OAM_XFLIP | OAM_YFLIP
	db -8, -8, 17, OAM_XFLIP | OAM_YFLIP
	db -16, 0, 18, OAM_XFLIP | OAM_YFLIP
	db -16, -8, 19, OAM_XFLIP | OAM_YFLIP
	db 16, -8, 4, $0
	db 16, 0, 5, $0
	db 24, -8, 6, $0
	db 24, 0, 7, $0
	db 19, 8, 22, $0
	db 16, 8, 12, $0
	db 24, 8, 13, $0
	db 25, -16, 20, $0
	db 8, 0, 23, $0
	db 32, -8, 23, OAM_XFLIP | OAM_YFLIP

.data_add65
	db 6 ; size
	db -10, -4, 14, $0
	db -2, -2, 15, $0
	db 0, -8, 8, OAM_XFLIP | OAM_YFLIP
	db 0, -16, 9, OAM_XFLIP | OAM_YFLIP
	db -8, -8, 10, OAM_XFLIP | OAM_YFLIP
	db -8, -16, 11, OAM_XFLIP | OAM_YFLIP

.data_add7e
	db 6 ; size
	db 0, -24, 16, $0
	db 0, -16, 17, $0
	db 8, -24, 18, $0
	db 8, -16, 19, $0
	db -2, -12, 12, $0
	db 7, -11, 13, $0

.data_add97
	db 6 ; size
	db 7, -19, 14, $0
	db 15, -17, 15, $0
	db 8, -32, 8, $0
	db 8, -24, 9, $0
	db 16, -32, 10, $0
	db 16, -24, 11, $0

.data_addb0
	db 5 ; size
	db 14, -28, 14, $0
	db 16, -32, 18, OAM_XFLIP | OAM_YFLIP
	db 16, -40, 19, OAM_XFLIP | OAM_YFLIP
	db 24, -32, 16, OAM_XFLIP | OAM_YFLIP
	db 24, -40, 17, OAM_XFLIP | OAM_YFLIP

AnimData115::
	frame_table AnimFrameTable42
	frame_data 0, 7, 0, 0
	frame_data 1, 7, 0, 0
	frame_data 2, 7, 0, 0
	frame_data 0, 7, -24, 24
	frame_data 1, 7, 0, 0
	frame_data 3, 7, 24, -24
	frame_data 4, 7, 0, 0
	frame_data 5, 7, 0, 0
	frame_data 6, 7, 0, 0
	frame_data 7, 7, 0, 0
	frame_data 8, 7, 0, 0
	frame_data 9, 7, 0, 0
	frame_data 10, 7, 0, 0
	frame_data 11, 7, 0, 0
	frame_data 12, 7, 0, 0
	frame_data 12, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimData116::
	frame_table AnimFrameTable43
	frame_data 0, 4, -24, 24
	frame_data 0, 4, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 1, 4, 0, 48
	frame_data 1, 4, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable43::
	dw .data_ade61
	dw .data_ade9a
	dw .data_aded3
	dw .data_adf14
	dw .data_adf65
	dw .data_adf6a
	dw .data_adf8b
	dw .data_adfac
	dw .data_adfcd

.data_ade61
	db 14 ; size
	db -18, 0, 0, $0
	db -16, 8, 1, $0
	db -10, -8, 2, $0
	db -10, 0, 3, $0
	db -8, 8, 4, $0
	db 0, -16, 5, $0
	db -2, -8, 6, $0
	db -2, 0, 7, $0
	db 8, -24, 8, $0
	db 8, -16, 9, $0
	db 8, -8, 10, $0
	db 16, -32, 11, $0
	db 16, -24, 12, $0
	db 16, -16, 13, $0

.data_ade9a
	db 14 ; size
	db -18, -8, 0, OAM_XFLIP
	db -16, -16, 1, OAM_XFLIP
	db -10, 0, 2, OAM_XFLIP
	db -10, -8, 3, OAM_XFLIP
	db -8, -16, 4, OAM_XFLIP
	db 0, 8, 5, OAM_XFLIP
	db -2, 0, 6, OAM_XFLIP
	db -2, -8, 7, OAM_XFLIP
	db 8, 16, 8, OAM_XFLIP
	db 8, 8, 9, OAM_XFLIP
	db 8, 0, 10, OAM_XFLIP
	db 16, 24, 11, OAM_XFLIP
	db 16, 16, 12, OAM_XFLIP
	db 16, 8, 13, OAM_XFLIP

.data_aded3
	db 16 ; size
	db -16, -16, 19, $0
	db -16, 8, 19, OAM_XFLIP
	db 8, 8, 19, OAM_XFLIP | OAM_YFLIP
	db 8, -16, 19, OAM_YFLIP
	db -16, -8, 20, $0
	db -16, 0, 20, OAM_XFLIP
	db 8, 0, 20, OAM_XFLIP | OAM_YFLIP
	db 8, -8, 20, OAM_YFLIP
	db -8, -16, 21, $0
	db -8, 8, 21, OAM_XFLIP
	db 0, 8, 21, OAM_XFLIP | OAM_YFLIP
	db 0, -16, 21, OAM_YFLIP
	db -8, -8, 22, $0
	db -8, 0, 22, OAM_XFLIP
	db 0, 0, 22, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 22, OAM_YFLIP

.data_adf14
	db 20 ; size
	db -26, -18, 14, $0
	db -18, -20, 15, $0
	db -18, -12, 16, $0
	db -10, -18, 17, $0
	db -10, -10, 18, $0
	db -26, 10, 14, OAM_XFLIP
	db -18, 12, 15, OAM_XFLIP
	db -18, 4, 16, OAM_XFLIP
	db -10, 10, 17, OAM_XFLIP
	db -10, 2, 18, OAM_XFLIP
	db 18, -18, 14, OAM_YFLIP
	db 10, -20, 15, OAM_YFLIP
	db 10, -12, 16, OAM_YFLIP
	db 2, -18, 17, OAM_YFLIP
	db 2, -10, 18, OAM_YFLIP
	db 18, 10, 14, OAM_XFLIP | OAM_YFLIP
	db 10, 12, 15, OAM_XFLIP | OAM_YFLIP
	db 10, 4, 16, OAM_XFLIP | OAM_YFLIP
	db 2, 10, 17, OAM_XFLIP | OAM_YFLIP
	db 2, 2, 18, OAM_XFLIP | OAM_YFLIP

.data_adf65
	db 1 ; size
	db -5, -4, 23, $0

.data_adf6a
	db 8 ; size
	db -13, 4, 24, $0
	db -1, 0, 24, $0
	db -17, -8, 24, OAM_XFLIP
	db -5, -12, 24, OAM_XFLIP
	db 3, -12, 26, OAM_XFLIP
	db 7, 0, 26, OAM_XFLIP
	db -9, -8, 26, $0
	db -5, 4, 26, $0

.data_adf8b
	db 8 ; size
	db -20, -9, 24, $0
	db 2, 1, 24, OAM_XFLIP
	db -14, 7, 25, $0
	db -4, -14, 25, $0
	db 4, -15, 26, $0
	db 10, 1, 26, $0
	db -12, -9, 26, OAM_XFLIP
	db -6, 7, 26, OAM_XFLIP

.data_adfac
	db 8 ; size
	db -16, 13, 24, $0
	db -2, -21, 24, OAM_XFLIP
	db -26, -11, 25, OAM_XFLIP
	db 8, 3, 25, $0
	db -18, -10, 26, $0
	db -8, 13, 26, $0
	db 6, -21, 26, OAM_XFLIP
	db 16, 2, 26, OAM_XFLIP

.data_adfcd
	db 8 ; size
	db -2, -21, 24, $0
	db 8, 3, 24, $0
	db -26, -11, 24, OAM_XFLIP
	db -16, 13, 24, OAM_XFLIP
	db 6, -21, 26, $0
	db 16, 3, 26, $0
	db -18, -11, 26, OAM_XFLIP
	db -8, 13, 26, OAM_XFLIP

AnimData117::
	frame_table AnimFrameTable43
	frame_data 0, 4, -24, 24
	frame_data 0, 4, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 2, 3, -24, 24
	frame_data -1, 3, 0, 0
	frame_data 3, 3, 0, 0
	frame_data -1, 3, 0, 0
	frame_data 3, 3, 0, 0
	frame_data 1, 4, 24, 24
	frame_data 1, 4, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 2, 3, 24, 24
	frame_data -1, 3, 0, 0
	frame_data 3, 3, 0, 0
	frame_data -1, 3, 0, 0
	frame_data 3, 3, 0, 0
	frame_data 3, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimData118::
	frame_table AnimFrameTable43
	frame_data 0, 4, -24, 24
	frame_data 0, 4, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 0, 3, 8, -8
	frame_data 4, 5, -24, 24
	frame_data 5, 5, 0, 0
	frame_data 6, 5, 0, 0
	frame_data 7, 5, 0, 0
	frame_data 8, 5, 0, 0
	frame_data 7, 5, 0, 0
	frame_data 8, 5, 0, 0
	frame_data 1, 4, 24, 24
	frame_data 1, 4, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 1, 3, -8, -8
	frame_data 4, 5, 24, 24
	frame_data 5, 5, 0, 0
	frame_data 6, 5, 0, 0
	frame_data 7, 5, 0, 0
	frame_data 8, 5, 0, 0
	frame_data 7, 5, 0, 0
	frame_data 8, 5, 0, 0
	frame_data 8, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimData119::
	frame_table AnimFrameTable44
	frame_data 0, 2, 0, 0
	frame_data 1, 2, 0, 0
	frame_data 2, 2, 0, 0
	frame_data 3, 2, 0, 0
	frame_data 4, 2, 0, 0
	frame_data 5, 2, 0, 0
	frame_data 6, 2, 0, 0
	frame_data 7, 2, 0, 0
	frame_data 8, 2, 0, 0
	frame_data 9, 2, 0, 0
	frame_data 10, 2, 0, 0
	frame_data 11, 8, 0, 0
	frame_data 9, 2, 0, 0
	frame_data 7, 2, 0, 0
	frame_data 5, 2, 0, 0
	frame_data 3, 2, 0, 0
	frame_data 1, 2, 0, 0
	frame_data -1, 2, 0, 0
	frame_data -1, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable44::
	dw .data_ae13f
	dw .data_ae148
	dw .data_ae159
	dw .data_ae172
	dw .data_ae18f
	dw .data_ae1b4
	dw .data_ae1e1
	dw .data_ae216
	dw .data_ae24b
	dw .data_ae270
	dw .data_ae28d
	dw .data_ae2a6

.data_ae13f
	db 2 ; size
	db -8, 32, 3, $0
	db 0, 32, 6, $0

.data_ae148
	db 4 ; size
	db -8, 32, 2, $0
	db -8, 40, 3, $0
	db 0, 32, 5, $0
	db 0, 40, 6, $0

.data_ae159
	db 6 ; size
	db -8, 32, 1, $0
	db -8, 40, 2, $0
	db -8, 48, 3, $0
	db 0, 32, 4, $0
	db 0, 40, 5, $0
	db 0, 48, 6, $0

.data_ae172
	db 7 ; size
	db -8, 40, 1, $0
	db -8, 48, 2, $0
	db -8, 56, 3, $0
	db 0, 40, 4, $0
	db 0, 48, 5, $0
	db 0, 56, 6, $0
	db -4, 32, 0, $0

.data_ae18f
	db 9 ; size
	db -8, 56, 1, $0
	db -8, 64, 2, $0
	db -8, 72, 3, $0
	db 0, 56, 4, $0
	db 0, 64, 5, $0
	db 0, 72, 6, $0
	db -4, 48, 0, $0
	db -4, 40, 0, $0
	db -4, 32, 0, $0

.data_ae1b4
	db 11 ; size
	db -8, 72, 1, $0
	db -8, 80, 2, $0
	db -8, 88, 3, $0
	db 0, 72, 4, $0
	db 0, 80, 5, $0
	db 0, 88, 6, $0
	db -4, 64, 0, $0
	db -4, 56, 0, $0
	db -4, 48, 0, $0
	db -4, 40, 0, $0
	db -4, 32, 0, $0

.data_ae1e1
	db 13 ; size
	db -8, 88, 1, $0
	db -8, 96, 2, $0
	db -8, 104, 3, $0
	db 0, 88, 4, $0
	db 0, 96, 5, $0
	db 0, 104, 6, $0
	db -4, 80, 0, $0
	db -4, 72, 0, $0
	db -4, 64, 0, $0
	db -4, 56, 0, $0
	db -4, 48, 0, $0
	db -4, 40, 0, $0
	db -4, 32, 0, $0

.data_ae216
	db 13 ; size
	db -8, 102, 1, $0
	db -8, 110, 2, $0
	db -8, 118, 3, $0
	db 0, 102, 4, $0
	db 0, 110, 5, $0
	db 0, 118, 6, $0
	db -4, 32, 0, $0
	db -4, 42, 7, $0
	db -4, 52, 7, $0
	db -4, 62, 7, $0
	db -4, 72, 7, $0
	db -4, 82, 7, $0
	db -4, 92, 7, $0

.data_ae24b
	db 9 ; size
	db -8, 120, 1, $0
	db 0, 120, 4, $0
	db -4, 32, 0, $0
	db -4, 44, 7, $0
	db -4, 56, 7, $0
	db -4, 68, 7, $0
	db -4, 80, 7, $0
	db -4, 92, 7, $0
	db -4, 104, 7, $0

.data_ae270
	db 7 ; size
	db -4, 32, 0, $0
	db -4, 46, 7, $0
	db -4, 60, 7, $0
	db -4, 74, 7, $0
	db -4, 88, 7, $0
	db -4, 102, 7, $0
	db -4, 116, 7, $0

.data_ae28d
	db 6 ; size
	db -4, 32, 0, $0
	db -4, 48, 7, $0
	db -4, 64, 7, $0
	db -4, 80, 7, $0
	db -4, 96, 7, $0
	db -4, 112, 7, $0

.data_ae2a6
	db 5 ; size
	db -4, 32, 0, $0
	db -4, 52, 7, $0
	db -4, 72, 7, $0
	db -4, 92, 7, $0
	db -4, 112, 7, $0

AnimData120::
	frame_table AnimFrameTable45
	frame_data 0, 4, 16, -16
	frame_data 0, 4, -16, 16
	frame_data 1, 4, 0, 0
	frame_data 2, 4, 0, 0
	frame_data 3, 4, 0, 0
	frame_data 4, 4, 0, 0
	frame_data 3, 4, 0, 0
	frame_data 4, 4, 0, 0
	frame_data 4, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable45::
	dw .data_ae306
	dw .data_ae31b
	dw .data_ae350
	dw .data_ae37d
	dw .data_ae39e
	dw .data_ae3bf
	dw .data_ae3e8
	dw .data_ae41d
	dw .data_ae442
	dw .data_ae477
	dw .data_ae498
	dw .data_ae4cd
	dw .data_ae4e2
	dw .data_ae517
	dw .data_ae544
	dw .data_ae565

.data_ae306
	db 5 ; size
	db 0, -6, 0, $0
	db -8, -6, 1, $0
	db -8, 2, 2, $0
	db -16, 2, 3, $0
	db -16, 10, 4, $0

.data_ae31b
	db 13 ; size
	db 16, -22, 0, $0
	db 8, -22, 1, $0
	db 8, -14, 2, $0
	db 0, -14, 3, $0
	db 0, -6, 4, $0
	db -3, -11, 5, $0
	db -11, -11, 6, $0
	db -11, -3, 7, $0
	db -19, -3, 8, $0
	db 3, -5, 9, $0
	db 3, 3, 10, $0
	db -5, 3, 11, $0
	db -5, 11, 12, $0

.data_ae350
	db 11 ; size
	db 24, -30, 2, $0
	db 16, -30, 3, $0
	db 16, -22, 4, $0
	db -2, -10, 5, $0
	db -10, -10, 6, $0
	db -10, -2, 7, $0
	db -18, -2, 8, $0
	db 2, -6, 9, $0
	db 2, 2, 10, $0
	db -6, 2, 11, $0
	db -6, 10, 12, $0

.data_ae37d
	db 8 ; size
	db -3, -11, 5, $0
	db -11, -11, 6, $0
	db -11, -3, 7, $0
	db -19, -3, 8, $0
	db 3, -5, 9, $0
	db 3, 3, 10, $0
	db -5, 3, 11, $0
	db -5, 11, 12, $0

.data_ae39e
	db 8 ; size
	db -2, -10, 5, $0
	db -10, -10, 6, $0
	db -10, -2, 7, $0
	db -18, -2, 8, $0
	db 2, -6, 9, $0
	db 2, 2, 10, $0
	db -6, 2, 11, $0
	db -6, 10, 12, $0

.data_ae3bf
	db 10 ; size
	db -2, -2, 5, $0
	db -10, -2, 6, $0
	db -10, 6, 7, $0
	db -18, 6, 8, $0
	db 2, 2, 9, $0
	db 2, 10, 10, $0
	db -6, 10, 11, $0
	db -6, 18, 12, $0
	db -24, -34, 0, OAM_XFLIP
	db -32, -38, 0, OAM_YFLIP

.data_ae3e8
	db 13 ; size
	db -3, -3, 5, $0
	db -11, -3, 6, $0
	db -11, 5, 7, $0
	db -19, 5, 8, $0
	db 3, 3, 9, $0
	db 3, 11, 10, $0
	db -5, 11, 11, $0
	db -5, 19, 12, $0
	db -8, -18, 0, OAM_XFLIP
	db -16, -18, 1, OAM_XFLIP
	db -16, -26, 2, OAM_XFLIP
	db -24, -26, 3, OAM_XFLIP
	db -24, -34, 4, OAM_XFLIP

.data_ae41d
	db 9 ; size
	db 8, -2, 0, OAM_XFLIP
	db 0, -2, 1, OAM_XFLIP
	db 0, -10, 2, OAM_XFLIP
	db -8, -10, 3, OAM_XFLIP
	db -8, -18, 4, OAM_XFLIP
	db -8, -10, 5, OAM_XFLIP
	db -16, -10, 6, OAM_XFLIP
	db -2, -16, 9, OAM_XFLIP
	db -2, -24, 10, OAM_XFLIP

.data_ae442
	db 13 ; size
	db 24, 14, 0, OAM_XFLIP
	db 16, 14, 1, OAM_XFLIP
	db 16, 6, 2, OAM_XFLIP
	db 8, 6, 3, OAM_XFLIP
	db 8, -2, 4, OAM_XFLIP
	db -4, -4, 5, OAM_XFLIP
	db -12, -4, 6, OAM_XFLIP
	db -12, -12, 7, OAM_XFLIP
	db -20, -12, 8, OAM_XFLIP
	db 4, -12, 9, OAM_XFLIP
	db 4, -20, 10, OAM_XFLIP
	db -4, -20, 11, OAM_XFLIP
	db -4, -28, 12, OAM_XFLIP

.data_ae477
	db 8 ; size
	db -3, -5, 5, OAM_XFLIP
	db -11, -5, 6, OAM_XFLIP
	db -11, -13, 7, OAM_XFLIP
	db -19, -13, 8, OAM_XFLIP
	db 3, -11, 9, OAM_XFLIP
	db 3, -19, 10, OAM_XFLIP
	db -5, -19, 11, OAM_XFLIP
	db -5, -27, 12, OAM_XFLIP

.data_ae498
	db 13 ; size
	db -4, -4, 5, OAM_XFLIP
	db -12, -4, 6, OAM_XFLIP
	db -12, -12, 7, OAM_XFLIP
	db -20, -12, 8, OAM_XFLIP
	db 4, -12, 9, OAM_XFLIP
	db 4, -20, 10, OAM_XFLIP
	db -4, -20, 11, OAM_XFLIP
	db -4, -28, 12, OAM_XFLIP
	db 8, 18, 0, OAM_YFLIP
	db 16, 18, 1, OAM_YFLIP
	db 16, 26, 2, OAM_YFLIP
	db 24, 26, 3, OAM_YFLIP
	db 24, 34, 4, OAM_YFLIP

.data_ae4cd
	db 5 ; size
	db -8, 2, 0, OAM_YFLIP
	db 0, 2, 1, OAM_YFLIP
	db 0, 10, 2, OAM_YFLIP
	db 8, 10, 3, OAM_YFLIP
	db 8, 18, 4, OAM_YFLIP

.data_ae4e2
	db 13 ; size
	db -24, -14, 0, OAM_YFLIP
	db -16, -14, 1, OAM_YFLIP
	db -16, -6, 2, OAM_YFLIP
	db -8, -6, 3, OAM_YFLIP
	db -8, 2, 4, OAM_YFLIP
	db -5, -3, 5, OAM_YFLIP
	db 3, -3, 6, OAM_YFLIP
	db 3, 5, 7, OAM_YFLIP
	db 11, 5, 8, OAM_YFLIP
	db -11, 3, 9, OAM_YFLIP
	db -11, 11, 10, OAM_YFLIP
	db -3, 11, 11, OAM_YFLIP
	db -3, 19, 12, OAM_YFLIP

.data_ae517
	db 11 ; size
	db -32, -22, 2, OAM_YFLIP
	db -24, -22, 3, OAM_YFLIP
	db -24, -14, 4, OAM_YFLIP
	db -6, -2, 5, OAM_YFLIP
	db 2, -2, 6, OAM_YFLIP
	db 2, 6, 7, OAM_YFLIP
	db 10, 6, 8, OAM_YFLIP
	db -10, 2, 9, OAM_YFLIP
	db -10, 10, 10, OAM_YFLIP
	db -2, 10, 11, OAM_YFLIP
	db -2, 18, 12, OAM_YFLIP

.data_ae544
	db 8 ; size
	db -5, -3, 5, OAM_YFLIP
	db 3, -3, 6, OAM_YFLIP
	db 3, 5, 7, OAM_YFLIP
	db 11, 5, 8, OAM_YFLIP
	db -11, 3, 9, OAM_YFLIP
	db -11, 11, 10, OAM_YFLIP
	db -3, 11, 11, OAM_YFLIP
	db -3, 19, 12, OAM_YFLIP

.data_ae565
	db 8 ; size
	db -6, -2, 5, OAM_YFLIP
	db 2, -2, 6, OAM_YFLIP
	db 2, 6, 7, OAM_YFLIP
	db 10, 6, 8, OAM_YFLIP
	db -10, 2, 9, OAM_YFLIP
	db -10, 10, 10, OAM_YFLIP
	db -2, 10, 11, OAM_YFLIP
	db -2, 18, 12, OAM_YFLIP

AnimData121::
	frame_table AnimFrameTable45
	frame_data 0, 4, 20, -16
	frame_data 0, 4, -16, 16
	frame_data 1, 4, 0, 0
	frame_data 2, 4, 0, 0
	frame_data 3, 4, 0, 0
	frame_data 5, 4, -8, 0
	frame_data 6, 4, 0, 0
	frame_data 7, 4, 0, 0
	frame_data 8, 4, 0, 0
	frame_data 9, 4, 0, 0
	frame_data 10, 4, 0, 0
	frame_data 11, 4, 0, 0
	frame_data 12, 4, 0, 0
	frame_data 13, 4, 0, 0
	frame_data 14, 4, 0, 0
	frame_data 15, 4, 0, 0
	frame_data 14, 4, 0, 0
	frame_data 15, 4, 0, 0
	frame_data 15, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimData122::
	frame_table AnimFrameTable46
	frame_data 0, 4, 0, 0
	frame_data 1, 4, 0, 0
	frame_data 2, 4, 0, 0
	frame_data 3, 4, 0, 0
	frame_data 4, 4, 0, 0
	frame_data 5, 4, 0, 0
	frame_data 6, 4, 0, 0
	frame_data 7, 4, 0, 0
	frame_data 8, 4, 0, 0
	frame_data 8, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable46::
	dw .data_ae61a
	dw .data_ae633
	dw .data_ae650
	dw .data_ae671
	dw .data_ae69a
	dw .data_ae6d3
	dw .data_ae704
	dw .data_ae735
	dw .data_ae75a

.data_ae61a
	db 6 ; size
	db 16, -14, 0, $0
	db 16, -6, 1, $0
	db 16, 2, 2, $0
	db 24, -14, 3, $0
	db 24, -6, 4, $0
	db 24, 2, 5, $0

.data_ae633
	db 7 ; size
	db 8, -10, 0, $0
	db 8, -2, 1, $0
	db 8, 6, 2, $0
	db 16, -10, 3, $0
	db 16, -2, 4, $0
	db 16, 6, 5, $0
	db 24, -2, 6, $0

.data_ae650
	db 8 ; size
	db 0, -4, 7, $0
	db 0, 4, 8, $0
	db 0, 12, 9, $0
	db 8, -4, 10, $0
	db 8, 4, 11, $0
	db 8, 12, 12, $0
	db 16, 0, 6, $0
	db 24, -3, 13, $0

.data_ae671
	db 10 ; size
	db -8, 1, 14, $0
	db -8, 9, 15, $0
	db 0, 11, 16, $0
	db 8, 3, 11, $0
	db 8, 11, 12, $0
	db 16, -1, 6, $0
	db 24, -4, 17, $0
	db -8, -8, 20, $0
	db 0, -8, 21, $0
	db 0, 0, 22, $0

.data_ae69a
	db 14 ; size
	db -24, 13, 18, $0
	db -16, 13, 19, $0
	db -8, 11, 16, $0
	db 0, 7, 6, $0
	db 8, 3, 6, $0
	db 16, -1, 6, $0
	db 24, -4, 17, $0
	db 0, -8, 23, $0
	db 0, 0, 24, $0
	db -16, -2, 29, $0
	db -16, 6, 30, $0
	db -8, -10, 31, $0
	db -8, -2, 32, $0
	db -8, 6, 33, $0

.data_ae6d3
	db 12 ; size
	db 0, 7, 6, $0
	db 8, 3, 6, $0
	db 16, -1, 6, $0
	db 24, -4, 17, $0
	db -8, 19, 14, OAM_XFLIP
	db -8, 11, 15, OAM_XFLIP
	db 0, -8, 21, $0
	db 0, 0, 22, $0
	db -16, -4, 25, $0
	db -16, 4, 26, $0
	db -8, -4, 27, $0
	db -8, 4, 28, $0

.data_ae704
	db 12 ; size
	db 8, 7, 6, $0
	db 16, 3, 6, $0
	db 24, -1, 6, $0
	db 0, 19, 14, OAM_XFLIP
	db 0, 11, 15, OAM_XFLIP
	db 0, -8, 23, $0
	db 0, 0, 24, $0
	db -16, -2, 29, $0
	db -16, 6, 30, $0
	db -8, -10, 31, $0
	db -8, -2, 32, $0
	db -8, 6, 33, $0

.data_ae735
	db 9 ; size
	db 24, 1, 6, $0
	db 16, 13, 14, OAM_XFLIP
	db 16, 5, 15, OAM_XFLIP
	db 0, -8, 21, $0
	db 0, 0, 22, $0
	db -16, -4, 25, $0
	db -16, 4, 26, $0
	db -8, -4, 27, $0
	db -8, 4, 28, $0

.data_ae75a
	db 9 ; size
	db 24, 13, 14, OAM_XFLIP
	db 24, 5, 15, OAM_XFLIP
	db 0, -8, 23, $0
	db 0, 0, 24, $0
	db -16, -2, 29, $0
	db -16, 6, 30, $0
	db -8, -10, 31, $0
	db -8, -2, 32, $0
	db -8, 6, 33, $0

AnimData123::
	frame_table AnimFrameTable47
	frame_data 0, 3, 0, 0
	frame_data 1, 2, 0, 0
	frame_data 2, 2, 0, 0
	frame_data 3, 2, 0, 0
	frame_data 4, 2, 0, 0
	frame_data 5, 2, 0, 0
	frame_data 6, 2, 0, 0
	frame_data 7, 2, 0, 0
	frame_data 8, 2, 0, 0
	frame_data 9, 2, 0, 0
	frame_data 10, 2, 0, 0
	frame_data 11, 2, 0, 0
	frame_data 12, 2, 0, 0
	frame_data 13, 2, 0, 0
	frame_data 14, 2, 0, 0
	frame_data 15, 2, 0, 0
	frame_data 16, 2, 0, 0
	frame_data 17, 2, 0, 0
	frame_data 18, 2, 0, 0
	frame_data 19, 2, 0, 0
	frame_data 20, 2, 0, 0
	frame_data 21, 2, 0, 0
	frame_data 22, 2, 0, 0
	frame_data 22, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable47::
	dw .data_ae814
	dw .data_ae845
	dw .data_ae886
	dw .data_ae8c7
	dw .data_ae918
	dw .data_ae969
	dw .data_ae9ca
	dw .data_aea2b
	dw .data_aea9c
	dw .data_aeb0d
	dw .data_aeb4e
	dw .data_aeb8f
	dw .data_aebd0
	dw .data_aec11
	dw .data_aec52
	dw .data_aec93
	dw .data_aecd4
	dw .data_aed15
	dw .data_aed46
	dw .data_aed77
	dw .data_aed98
	dw .data_aedb9
	dw .data_aedca

.data_ae814
	db 12 ; size
	db -8, -32, 3, $0
	db -8, -24, 4, $0
	db 0, -32, 3, OAM_YFLIP
	db 0, -24, 4, OAM_YFLIP
	db -8, -40, 2, $0
	db -8, -48, 1, $0
	db -16, -40, 0, $0
	db -20, -48, 0, $0
	db 0, -40, 2, OAM_YFLIP
	db 0, -48, 1, OAM_YFLIP
	db 8, -40, 0, OAM_YFLIP
	db 12, -48, 0, OAM_YFLIP

.data_ae845
	db 16 ; size
	db 12, -32, 0, OAM_YFLIP
	db 8, -24, 0, OAM_YFLIP
	db 0, -32, 1, OAM_YFLIP
	db 0, -24, 2, OAM_YFLIP
	db 0, -16, 3, OAM_YFLIP
	db 0, -8, 4, OAM_YFLIP
	db -10, -24, 5, $0
	db -11, -32, 6, $0
	db -20, -32, 0, $0
	db -16, -24, 0, $0
	db -8, -32, 1, $0
	db -8, -24, 2, $0
	db -8, -16, 3, $0
	db -8, -8, 4, $0
	db 2, -24, 5, OAM_YFLIP
	db 3, -32, 6, OAM_YFLIP

.data_ae886
	db 16 ; size
	db 12, -32, 0, OAM_YFLIP
	db 8, -24, 0, OAM_YFLIP
	db 0, -32, 1, OAM_YFLIP
	db 0, -24, 2, OAM_YFLIP
	db 0, -16, 3, OAM_YFLIP
	db 0, -8, 4, OAM_YFLIP
	db -9, -24, 5, $0
	db -10, -32, 6, $0
	db -20, -32, 0, $0
	db -16, -24, 0, $0
	db -8, -32, 1, $0
	db -8, -24, 2, $0
	db -8, -16, 3, $0
	db -8, -8, 4, $0
	db 1, -24, 5, OAM_YFLIP
	db 2, -32, 6, OAM_YFLIP

.data_ae8c7
	db 20 ; size
	db 12, -16, 0, OAM_YFLIP
	db 8, -8, 0, OAM_YFLIP
	db 0, -16, 1, OAM_YFLIP
	db 0, -8, 2, OAM_YFLIP
	db 0, 0, 3, OAM_YFLIP
	db 0, 8, 4, OAM_YFLIP
	db -10, -8, 5, $0
	db -11, -16, 6, $0
	db -12, -24, 7, $0
	db -13, -32, 8, $0
	db -20, -16, 0, $0
	db -16, -8, 0, $0
	db -8, -16, 1, $0
	db -8, -8, 2, $0
	db -8, 0, 3, $0
	db -8, 8, 4, $0
	db 2, -8, 5, OAM_YFLIP
	db 3, -16, 6, OAM_YFLIP
	db 4, -24, 7, OAM_YFLIP
	db 5, -32, 8, OAM_YFLIP

.data_ae918
	db 20 ; size
	db 12, -16, 0, OAM_YFLIP
	db 8, -8, 0, OAM_YFLIP
	db 0, -16, 1, OAM_YFLIP
	db 0, -8, 2, OAM_YFLIP
	db 0, 0, 3, OAM_YFLIP
	db 0, 8, 4, OAM_YFLIP
	db -9, -8, 5, $0
	db -10, -16, 6, $0
	db -11, -24, 7, $0
	db -12, -32, 8, $0
	db -20, -16, 0, $0
	db -16, -8, 0, $0
	db -8, -16, 1, $0
	db -8, -8, 2, $0
	db -8, 0, 3, $0
	db -8, 8, 4, $0
	db 1, -8, 5, OAM_YFLIP
	db 2, -16, 6, OAM_YFLIP
	db 3, -24, 7, OAM_YFLIP
	db 4, -32, 8, OAM_YFLIP

.data_ae969
	db 24 ; size
	db 12, 0, 0, OAM_YFLIP
	db 8, 8, 0, OAM_YFLIP
	db 0, 0, 1, OAM_YFLIP
	db 0, 8, 2, OAM_YFLIP
	db 0, 16, 3, OAM_YFLIP
	db 0, 24, 4, OAM_YFLIP
	db -10, 8, 5, $0
	db -11, 0, 6, $0
	db -12, -8, 7, $0
	db -13, -16, 8, $0
	db -14, -24, 8, $0
	db -15, -32, 8, $0
	db -20, 0, 0, $0
	db -16, 8, 0, $0
	db -8, 0, 1, $0
	db -8, 8, 2, $0
	db -8, 16, 3, $0
	db -8, 24, 4, $0
	db 2, 8, 5, OAM_YFLIP
	db 3, 0, 6, OAM_YFLIP
	db 4, -8, 7, OAM_YFLIP
	db 5, -16, 8, OAM_YFLIP
	db 6, -24, 8, OAM_YFLIP
	db 7, -32, 8, OAM_YFLIP

.data_ae9ca
	db 24 ; size
	db 12, 0, 0, OAM_YFLIP
	db 8, 8, 0, OAM_YFLIP
	db 0, 0, 1, OAM_YFLIP
	db 0, 8, 2, OAM_YFLIP
	db 0, 16, 3, OAM_YFLIP
	db 0, 24, 4, OAM_YFLIP
	db -9, 8, 5, $0
	db -10, 0, 6, $0
	db -11, -8, 7, $0
	db -12, -16, 8, $0
	db -13, -24, 8, $0
	db -14, -32, 8, $0
	db -20, 0, 0, $0
	db -16, 8, 0, $0
	db -8, 0, 1, $0
	db -8, 8, 2, $0
	db -8, 16, 3, $0
	db -8, 24, 4, $0
	db 1, 8, 5, OAM_YFLIP
	db 2, 0, 6, OAM_YFLIP
	db 3, -8, 7, OAM_YFLIP
	db 4, -16, 8, OAM_YFLIP
	db 5, -24, 8, OAM_YFLIP
	db 6, -32, 8, OAM_YFLIP

.data_aea2b
	db 28 ; size
	db 12, 16, 0, OAM_YFLIP
	db 8, 24, 0, OAM_YFLIP
	db 0, 16, 1, OAM_YFLIP
	db 0, 24, 2, OAM_YFLIP
	db -10, 24, 5, $0
	db -11, 16, 6, $0
	db -12, 8, 7, $0
	db -13, 0, 8, $0
	db -14, -8, 8, $0
	db -15, -16, 8, $0
	db -16, -24, 8, $0
	db -17, -32, 8, $0
	db -20, 16, 0, $0
	db -16, 24, 0, $0
	db -8, 16, 1, $0
	db -8, 24, 2, $0
	db 2, 24, 5, OAM_YFLIP
	db 3, 16, 6, OAM_YFLIP
	db 4, 8, 7, OAM_YFLIP
	db 5, 0, 8, OAM_YFLIP
	db 6, -8, 8, OAM_YFLIP
	db 7, -16, 8, OAM_YFLIP
	db 8, -24, 8, OAM_YFLIP
	db 9, -32, 8, OAM_YFLIP
	db 0, 32, 3, OAM_YFLIP
	db 0, 40, 4, OAM_YFLIP
	db -8, 32, 3, $0
	db -8, 40, 4, $0

.data_aea9c
	db 28 ; size
	db 12, 16, 0, OAM_YFLIP
	db 8, 24, 0, OAM_YFLIP
	db 0, 16, 1, OAM_YFLIP
	db 0, 24, 2, OAM_YFLIP
	db -9, 24, 5, $0
	db -10, 16, 6, $0
	db -11, 8, 7, $0
	db -12, 0, 8, $0
	db -13, -8, 8, $0
	db -14, -16, 8, $0
	db -15, -24, 8, $0
	db -16, -32, 8, $0
	db -20, 16, 0, $0
	db -16, 24, 0, $0
	db -8, 16, 1, $0
	db -8, 24, 2, $0
	db 1, 24, 5, OAM_YFLIP
	db 2, 16, 6, OAM_YFLIP
	db 3, 8, 7, OAM_YFLIP
	db 4, 0, 8, OAM_YFLIP
	db 5, -8, 8, OAM_YFLIP
	db 6, -16, 8, OAM_YFLIP
	db 7, -24, 8, OAM_YFLIP
	db 8, -32, 8, OAM_YFLIP
	db 0, 32, 3, OAM_YFLIP
	db 0, 40, 4, OAM_YFLIP
	db -8, 32, 3, $0
	db -8, 40, 4, $0

.data_aeb0d
	db 16 ; size
	db -12, 24, 7, $0
	db -13, 16, 8, $0
	db -14, 8, 8, $0
	db -15, 0, 8, $0
	db -16, -8, 8, $0
	db -17, -16, 8, $0
	db -18, -24, 8, $0
	db -19, -32, 8, $0
	db 4, 24, 7, OAM_YFLIP
	db 5, 16, 8, OAM_YFLIP
	db 6, 8, 8, OAM_YFLIP
	db 7, 0, 8, OAM_YFLIP
	db 8, -8, 8, OAM_YFLIP
	db 9, -16, 8, OAM_YFLIP
	db 10, -24, 8, OAM_YFLIP
	db 11, -32, 8, OAM_YFLIP

.data_aeb4e
	db 16 ; size
	db -11, 24, 7, $0
	db -12, 16, 8, $0
	db -13, 8, 8, $0
	db -14, 0, 8, $0
	db -15, -8, 8, $0
	db -16, -16, 8, $0
	db -17, -24, 8, $0
	db -18, -32, 8, $0
	db 3, 24, 7, OAM_YFLIP
	db 4, 16, 8, OAM_YFLIP
	db 5, 8, 8, OAM_YFLIP
	db 6, 0, 8, OAM_YFLIP
	db 7, -8, 8, OAM_YFLIP
	db 8, -16, 8, OAM_YFLIP
	db 9, -24, 8, OAM_YFLIP
	db 10, -32, 8, OAM_YFLIP

.data_aeb8f
	db 16 ; size
	db -14, 24, 8, $0
	db -15, 16, 8, $0
	db -16, 8, 8, $0
	db -17, 0, 8, $0
	db -18, -8, 8, $0
	db -19, -16, 8, $0
	db -20, -24, 9, $0
	db -21, -32, 9, $0
	db 6, 24, 8, OAM_YFLIP
	db 7, 16, 8, OAM_YFLIP
	db 8, 8, 8, OAM_YFLIP
	db 9, 0, 8, OAM_YFLIP
	db 10, -8, 8, OAM_YFLIP
	db 11, -16, 8, OAM_YFLIP
	db 12, -24, 9, OAM_YFLIP
	db 13, -32, 9, OAM_YFLIP

.data_aebd0
	db 16 ; size
	db -13, 24, 8, $0
	db -14, 16, 8, $0
	db -15, 8, 8, $0
	db -16, 0, 8, $0
	db -17, -8, 8, $0
	db -18, -16, 8, $0
	db -19, -24, 9, $0
	db -20, -32, 9, $0
	db 5, 24, 8, OAM_YFLIP
	db 6, 16, 8, OAM_YFLIP
	db 7, 8, 8, OAM_YFLIP
	db 8, 0, 8, OAM_YFLIP
	db 9, -8, 8, OAM_YFLIP
	db 10, -16, 8, OAM_YFLIP
	db 11, -24, 9, OAM_YFLIP
	db 12, -32, 9, OAM_YFLIP

.data_aec11
	db 16 ; size
	db -16, 24, 8, $0
	db -17, 16, 8, $0
	db -18, 8, 8, $0
	db -19, 0, 8, $0
	db -20, -8, 9, $0
	db -21, -16, 9, $0
	db -23, -32, 10, $0
	db -22, -24, 10, $0
	db 8, 24, 8, OAM_YFLIP
	db 9, 16, 8, OAM_YFLIP
	db 10, 8, 8, OAM_YFLIP
	db 11, 0, 8, OAM_YFLIP
	db 12, -8, 9, OAM_YFLIP
	db 13, -16, 9, OAM_YFLIP
	db 15, -32, 10, OAM_YFLIP
	db 14, -24, 10, OAM_YFLIP

.data_aec52
	db 16 ; size
	db -15, 24, 8, $0
	db -16, 16, 8, $0
	db -17, 8, 8, $0
	db -18, 0, 8, $0
	db -19, -8, 9, $0
	db -20, -16, 9, $0
	db -22, -32, 10, $0
	db -21, -24, 10, $0
	db 7, 24, 8, OAM_YFLIP
	db 8, 16, 8, OAM_YFLIP
	db 9, 8, 8, OAM_YFLIP
	db 10, 0, 8, OAM_YFLIP
	db 11, -8, 9, OAM_YFLIP
	db 12, -16, 9, OAM_YFLIP
	db 14, -32, 10, OAM_YFLIP
	db 13, -24, 10, OAM_YFLIP

.data_aec93
	db 16 ; size
	db -18, 24, 8, $0
	db -19, 16, 8, $0
	db -20, 8, 9, $0
	db -21, 0, 9, $0
	db -23, -16, 10, $0
	db -22, -8, 10, $0
	db -25, -32, 11, $0
	db -24, -24, 11, $0
	db 10, 24, 8, OAM_YFLIP
	db 11, 16, 8, OAM_YFLIP
	db 12, 8, 9, OAM_YFLIP
	db 13, 0, 9, OAM_YFLIP
	db 15, -16, 10, OAM_YFLIP
	db 14, -8, 10, OAM_YFLIP
	db 17, -32, 11, OAM_YFLIP
	db 16, -24, 11, OAM_YFLIP

.data_aecd4
	db 16 ; size
	db -17, 24, 8, $0
	db -18, 16, 8, $0
	db -19, 8, 9, $0
	db -20, 0, 9, $0
	db -22, -16, 10, $0
	db -21, -8, 10, $0
	db -24, -32, 11, $0
	db -23, -24, 11, $0
	db 9, 24, 8, OAM_YFLIP
	db 10, 16, 8, OAM_YFLIP
	db 11, 8, 9, OAM_YFLIP
	db 12, 0, 9, OAM_YFLIP
	db 14, -16, 10, OAM_YFLIP
	db 13, -8, 10, OAM_YFLIP
	db 16, -32, 11, OAM_YFLIP
	db 15, -24, 11, OAM_YFLIP

.data_aed15
	db 12 ; size
	db -20, 24, 9, $0
	db -21, 16, 9, $0
	db -23, 0, 10, $0
	db -22, 8, 10, $0
	db -25, -16, 11, $0
	db -24, -8, 11, $0
	db 12, 24, 9, OAM_YFLIP
	db 13, 16, 9, OAM_YFLIP
	db 15, 0, 10, OAM_YFLIP
	db 14, 8, 10, OAM_YFLIP
	db 17, -16, 11, OAM_YFLIP
	db 16, -8, 11, OAM_YFLIP

.data_aed46
	db 12 ; size
	db -19, 24, 9, $0
	db -20, 16, 9, $0
	db -22, 0, 10, $0
	db -21, 8, 10, $0
	db -24, -16, 11, $0
	db -23, -8, 11, $0
	db 11, 24, 9, OAM_YFLIP
	db 12, 16, 9, OAM_YFLIP
	db 14, 0, 10, OAM_YFLIP
	db 13, 8, 10, OAM_YFLIP
	db 16, -16, 11, OAM_YFLIP
	db 15, -8, 11, OAM_YFLIP

.data_aed77
	db 8 ; size
	db -23, 16, 10, $0
	db -22, 24, 10, $0
	db -25, 0, 11, $0
	db -24, 8, 11, $0
	db 15, 16, 10, OAM_YFLIP
	db 14, 24, 10, OAM_YFLIP
	db 17, 0, 11, OAM_YFLIP
	db 16, 8, 11, OAM_YFLIP

.data_aed98
	db 8 ; size
	db -22, 16, 10, $0
	db -21, 24, 10, $0
	db -24, 0, 11, $0
	db -23, 8, 11, $0
	db 14, 16, 10, OAM_YFLIP
	db 13, 24, 10, OAM_YFLIP
	db 16, 0, 11, OAM_YFLIP
	db 15, 8, 11, OAM_YFLIP

.data_aedb9
	db 4 ; size
	db -25, 16, 11, $0
	db -24, 24, 11, $0
	db 17, 16, 11, OAM_YFLIP
	db 16, 24, 11, OAM_YFLIP

.data_aedca
	db 4 ; size
	db -24, 16, 11, $0
	db -23, 24, 11, $0
	db 16, 16, 11, OAM_YFLIP
	db 15, 24, 11, OAM_YFLIP

AnimData124::
	frame_table AnimFrameTable48
	frame_data 0, 2, -32, -24
	frame_data 1, 2, 0, 0
	frame_data 2, 2, 0, 0
	frame_data 0, 2, 8, 8
	frame_data 1, 2, 0, 0
	frame_data 2, 2, 0, 0
	frame_data 0, 2, 8, 8
	frame_data 1, 2, 0, 0
	frame_data 2, 2, 0, 0
	frame_data 0, 2, 8, 8
	frame_data 1, 2, 0, 0
	frame_data 2, 2, 0, 0
	frame_data 0, 2, 8, 8
	frame_data 1, 2, 0, 0
	frame_data 2, 2, 0, 0
	frame_data 3, 2, 0, 0
	frame_data 4, 2, 0, 0
	frame_data 5, 2, 0, 0
	frame_data 3, 2, 0, 0
	frame_data 4, 2, 0, 0
	frame_data 5, 2, 0, 0
	frame_data 3, 2, 0, 0
	frame_data 4, 2, 0, 0
	frame_data 5, 2, 0, 0
	frame_data 3, 2, 0, 0
	frame_data 4, 2, 0, 0
	frame_data 5, 2, 0, 0
	frame_data 0, 2, -16, -16
	frame_data 1, 2, 0, 0
	frame_data 2, 2, 0, 0
	frame_data 0, 2, -16, -16
	frame_data 1, 2, 0, 0
	frame_data 2, 2, 0, 0
	frame_data 2, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable48::
	dw .data_aee76
	dw .data_aeeab
	dw .data_aeee0
	dw .data_aef15
	dw .data_aef5e
	dw .data_aefa7

.data_aee76
	db 13 ; size
	db -32, -16, 0, OAM_XFLIP
	db -32, -24, 1, OAM_XFLIP
	db -24, -8, 2, OAM_XFLIP
	db -24, -16, 3, OAM_XFLIP
	db -24, -24, 4, OAM_XFLIP
	db -24, -32, 5, OAM_XFLIP
	db -16, -8, 6, OAM_XFLIP
	db -16, -16, 7, OAM_XFLIP
	db -16, -24, 8, OAM_XFLIP
	db -16, -32, 9, OAM_XFLIP
	db -8, -8, 10, OAM_XFLIP
	db -8, -16, 9, OAM_XFLIP
	db -8, -24, 2, OAM_YFLIP

.data_aeeab
	db 13 ; size
	db -32, -16, 0, OAM_XFLIP
	db -24, -8, 2, OAM_XFLIP
	db -24, -32, 5, OAM_XFLIP
	db -16, -24, 8, OAM_XFLIP
	db -16, -32, 9, OAM_XFLIP
	db -8, -16, 9, OAM_XFLIP
	db -8, -24, 2, OAM_YFLIP
	db -32, -24, 11, OAM_XFLIP
	db -24, -16, 12, OAM_XFLIP
	db -24, -24, 13, OAM_XFLIP
	db -16, -8, 14, OAM_XFLIP
	db -16, -16, 15, OAM_XFLIP
	db -8, -8, 16, OAM_XFLIP

.data_aeee0
	db 13 ; size
	db -24, -8, 2, OAM_XFLIP
	db -24, -32, 5, OAM_XFLIP
	db -16, -24, 8, OAM_XFLIP
	db -16, -32, 9, OAM_XFLIP
	db -8, -16, 9, OAM_XFLIP
	db -8, -24, 2, OAM_YFLIP
	db -32, -16, 17, OAM_XFLIP
	db -32, -24, 18, OAM_XFLIP
	db -24, -16, 19, OAM_XFLIP
	db -24, -24, 20, OAM_XFLIP
	db -16, -8, 21, OAM_XFLIP
	db -16, -16, 22, OAM_XFLIP
	db -8, -8, 23, OAM_XFLIP

.data_aef15
	db 18 ; size
	db -32, -16, 0, OAM_XFLIP
	db -32, -24, 1, OAM_XFLIP
	db -24, -8, 2, OAM_XFLIP
	db -24, -16, 3, OAM_XFLIP
	db -24, -24, 4, OAM_XFLIP
	db -24, -32, 5, OAM_XFLIP
	db -16, -8, 6, OAM_XFLIP
	db -16, -16, 7, OAM_XFLIP
	db -16, -24, 8, OAM_XFLIP
	db -16, -32, 9, OAM_XFLIP
	db -8, -16, 9, OAM_XFLIP
	db -8, -24, 2, OAM_YFLIP
	db -8, 0, 24, OAM_XFLIP
	db -8, -8, 25, OAM_XFLIP
	db 0, 0, 26, OAM_XFLIP
	db 0, -8, 27, OAM_XFLIP
	db 4, 4, 36, $0
	db 2, -20, 36, $0

.data_aef5e
	db 18 ; size
	db -31, -16, 0, OAM_XFLIP
	db -23, -8, 2, OAM_XFLIP
	db -23, -32, 5, OAM_XFLIP
	db -15, -24, 8, OAM_XFLIP
	db -15, -32, 9, OAM_XFLIP
	db -7, -16, 9, OAM_XFLIP
	db -7, -24, 2, OAM_YFLIP
	db -31, -24, 11, OAM_XFLIP
	db -23, -16, 12, OAM_XFLIP
	db -23, -24, 13, OAM_XFLIP
	db -15, -8, 14, OAM_XFLIP
	db -15, -16, 15, OAM_XFLIP
	db -7, 0, 28, OAM_XFLIP
	db -7, -8, 29, OAM_XFLIP
	db 1, 0, 30, OAM_XFLIP
	db 1, -8, 31, OAM_XFLIP
	db -16, 1, 36, $0
	db 10, 10, 36, $0

.data_aefa7
	db 18 ; size
	db -24, -8, 2, OAM_XFLIP
	db -24, -32, 5, OAM_XFLIP
	db -16, -24, 8, OAM_XFLIP
	db -16, -32, 9, OAM_XFLIP
	db -8, -16, 9, OAM_XFLIP
	db -8, -24, 2, OAM_YFLIP
	db -32, -16, 17, OAM_XFLIP
	db -32, -24, 18, OAM_XFLIP
	db -24, -16, 19, OAM_XFLIP
	db -24, -24, 20, OAM_XFLIP
	db -16, -8, 21, OAM_XFLIP
	db -16, -16, 22, OAM_XFLIP
	db -8, 0, 32, OAM_XFLIP
	db -8, -8, 33, OAM_XFLIP
	db 0, 0, 34, OAM_XFLIP
	db 0, -8, 35, OAM_XFLIP
	db -1, -13, 36, $0
	db -24, 4, 36, $0

AnimData125::
	frame_table AnimFrameTable49
	frame_data 0, 5, 0, -40
	frame_data 0, 5, 0, 8
	frame_data 0, 5, 0, 8
	frame_data 0, 5, 0, 8
	frame_data 1, 4, 0, 8
	frame_data 0, 4, 0, -4
	frame_data 0, 4, 0, -2
	frame_data 0, 4, 0, 2
	frame_data 2, 4, 2, 4
	frame_data 3, 5, 0, 0
	frame_data 3, 5, 4, -6
	frame_data 3, 5, 6, -5
	frame_data 3, 5, 8, -4
	frame_data 3, 5, 10, -3
	frame_data 3, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable49::
	dw .data_af03b
	dw .data_af06c
	dw .data_af0a9
	dw .data_af0ea

.data_af03b
	db 12 ; size
	db -16, 8, 0, $0
	db -8, -8, 1, $0
	db -8, 0, 2, $0
	db -8, 8, 3, $0
	db 0, -16, 4, $0
	db 0, -8, 5, $0
	db 0, 0, 6, $0
	db 0, 8, 7, $0
	db 8, -16, 8, $0
	db 8, -8, 9, $0
	db 8, 0, 10, $0
	db 8, 8, 11, $0

.data_af06c
	db 15 ; size
	db -16, 8, 0, $0
	db -8, 0, 2, $0
	db -8, 8, 3, $0
	db 0, -8, 5, $0
	db 0, 0, 6, $0
	db 0, 8, 7, $0
	db -8, -8, 12, $0
	db 0, -16, 13, $0
	db 8, -16, 14, $0
	db 8, -8, 15, $0
	db 8, 0, 16, $0
	db 8, 8, 17, $0
	db 16, -14, 31, $0
	db 16, -6, 32, $0
	db 16, 2, 33, $0

.data_af0a9
	db 16 ; size
	db -4, -24, 18, $0
	db -8, -16, 19, $0
	db -8, -8, 20, $0
	db -8, 0, 21, $0
	db -8, 8, 22, $0
	db 0, -16, 23, $0
	db 0, -8, 24, $0
	db 0, 0, 25, $0
	db 0, 8, 26, $0
	db 8, -16, 27, $0
	db 8, -8, 28, $0
	db 8, 0, 29, $0
	db 8, 8, 30, $0
	db 16, -16, 31, $0
	db 16, -8, 32, $0
	db 16, 0, 33, $0

.data_af0ea
	db 12 ; size
	db -16, -8, 0, OAM_XFLIP
	db -8, 8, 1, OAM_XFLIP
	db -8, 0, 2, OAM_XFLIP
	db -8, -8, 3, OAM_XFLIP
	db 0, 16, 4, OAM_XFLIP
	db 0, 8, 5, OAM_XFLIP
	db 0, 0, 6, OAM_XFLIP
	db 0, -8, 7, OAM_XFLIP
	db 8, 16, 8, OAM_XFLIP
	db 8, 8, 9, OAM_XFLIP
	db 8, 0, 10, OAM_XFLIP
	db 8, -8, 11, OAM_XFLIP

AnimData126::
	frame_table AnimFrameTable50
	frame_data 0, 2, 0, 0
	frame_data 1, 2, 2, 4
	frame_data 2, 2, 2, 4
	frame_data 3, 2, 2, 4
	frame_data 0, 2, 2, 4
	frame_data 1, 2, 2, 4
	frame_data 2, 2, 2, 4
	frame_data 3, 2, 2, 4
	frame_data 0, 2, 2, 4
	frame_data 1, 2, 2, 3
	frame_data 2, 2, 2, 3
	frame_data 3, 2, 2, 3
	frame_data 0, 2, 3, 3
	frame_data 1, 2, 3, 3
	frame_data 2, 2, 3, 3
	frame_data 3, 2, 3, 3
	frame_data 4, 2, 3, 3
	frame_data 5, 2, 3, 3
	frame_data 6, 2, 3, 3
	frame_data 7, 2, 3, 2
	frame_data 0, 2, 3, 1
	frame_data 1, 2, 3, 1
	frame_data 2, 2, 3, 0
	frame_data 3, 2, 2, 0
	frame_data 0, 2, 2, -1
	frame_data 1, 2, 1, -1
	frame_data 2, 2, 1, -2
	frame_data 3, 2, 1, -2
	frame_data 0, 2, 0, -3
	frame_data 1, 2, 0, -3
	frame_data 2, 2, -1, -3
	frame_data 3, 2, -1, -3
	frame_data 0, 2, -2, -2
	frame_data 1, 2, -2, -2
	frame_data 8, 2, -3, -3
	frame_data 9, 2, -3, -3
	frame_data 10, 2, -3, -3
	frame_data 11, 2, -4, -3
	frame_data 2, 2, -4, -3
	frame_data 3, 2, -4, -3
	frame_data 0, 2, -4, -2
	frame_data 1, 2, -4, -2
	frame_data 2, 2, -4, -2
	frame_data 3, 2, -4, -2
	frame_data 0, 2, -4, -2
	frame_data 1, 2, -4, -2
	frame_data 2, 2, -4, -2
	frame_data 3, 2, -4, -2
	frame_data 0, 2, -4, -2
	frame_data 0, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable50::
	dw .data_af202
	dw .data_af20f
	dw .data_af220
	dw .data_af22d
	dw .data_af23e
	dw .data_af25b
	dw .data_af27c
	dw .data_af299
	dw .data_af2ba
	dw .data_af2d7
	dw .data_af2f8
	dw .data_af315

.data_af202
	db 3 ; size
	db -52, -52, 6, $0
	db -52, -44, 7, $0
	db -52, -36, 6, OAM_XFLIP

.data_af20f
	db 4 ; size
	db -55, -52, 3, $0
	db -55, -44, 4, $0
	db -47, -44, 4, OAM_XFLIP | OAM_YFLIP
	db -47, -36, 5, $0

.data_af220
	db 3 ; size
	db -59, -44, 0, $0
	db -51, -44, 1, $0
	db -43, -44, 2, $0

.data_af22d
	db 4 ; size
	db -55, -36, 3, OAM_XFLIP
	db -55, -44, 4, OAM_XFLIP
	db -47, -44, 4, OAM_YFLIP
	db -47, -52, 5, OAM_XFLIP

.data_af23e
	db 7 ; size
	db -52, -52, 6, $0
	db -52, -44, 7, $0
	db -52, -36, 6, OAM_XFLIP
	db -66, -58, 8, $0
	db -66, -50, 9, $0
	db -58, -58, 10, $0
	db -58, -50, 11, $0

.data_af25b
	db 8 ; size
	db -55, -52, 3, $0
	db -55, -44, 4, $0
	db -47, -44, 4, OAM_XFLIP | OAM_YFLIP
	db -47, -36, 5, $0
	db -61, -61, 8, OAM_YFLIP
	db -61, -53, 9, OAM_YFLIP
	db -69, -61, 10, OAM_YFLIP
	db -69, -53, 11, OAM_YFLIP

.data_af27c
	db 7 ; size
	db -59, -44, 0, $0
	db -51, -44, 1, $0
	db -43, -44, 2, $0
	db -72, -64, 8, $0
	db -72, -56, 9, $0
	db -64, -64, 10, $0
	db -64, -56, 11, $0

.data_af299
	db 8 ; size
	db -66, -67, 8, OAM_YFLIP
	db -66, -59, 9, OAM_YFLIP
	db -74, -67, 10, OAM_YFLIP
	db -74, -59, 11, OAM_YFLIP
	db -55, -36, 3, OAM_XFLIP
	db -55, -44, 4, OAM_XFLIP
	db -47, -44, 4, OAM_YFLIP
	db -47, -52, 5, OAM_XFLIP

.data_af2ba
	db 7 ; size
	db -59, -44, 0, $0
	db -51, -44, 1, $0
	db -43, -44, 2, $0
	db -46, -38, 8, $0
	db -46, -30, 9, $0
	db -38, -38, 10, $0
	db -38, -30, 11, $0

.data_af2d7
	db 8 ; size
	db -55, -36, 3, OAM_XFLIP
	db -55, -44, 4, OAM_XFLIP
	db -47, -44, 4, OAM_YFLIP
	db -47, -52, 5, OAM_XFLIP
	db -35, -35, 8, OAM_YFLIP
	db -35, -27, 9, OAM_YFLIP
	db -43, -35, 10, OAM_YFLIP
	db -43, -27, 11, OAM_YFLIP

.data_af2f8
	db 7 ; size
	db -52, -52, 6, $0
	db -52, -44, 7, $0
	db -52, -36, 6, OAM_XFLIP
	db -40, -32, 8, $0
	db -40, -24, 9, $0
	db -32, -32, 10, $0
	db -32, -24, 11, $0

.data_af315
	db 8 ; size
	db -29, -28, 8, OAM_YFLIP
	db -29, -20, 9, OAM_YFLIP
	db -37, -28, 10, OAM_YFLIP
	db -37, -20, 11, OAM_YFLIP
	db -55, -52, 3, $0
	db -55, -44, 4, $0
	db -47, -44, 4, OAM_XFLIP | OAM_YFLIP
	db -47, -36, 5, $0

AnimData127::
	frame_table AnimFrameTable51
	frame_data 0, 2, 0, -72
	frame_data 0, 2, 0, 8
	frame_data 0, 2, 0, 8
	frame_data 0, 2, 0, 8
	frame_data 0, 2, 0, 8
	frame_data 0, 2, 0, 8
	frame_data 0, 2, 0, 8
	frame_data 0, 2, 0, 8
	frame_data 0, 2, 0, 8
	frame_data 1, 2, 0, 8
	frame_data 2, 4, 0, 0
	frame_data 3, 4, 0, 0
	frame_data 4, 4, 0, 0
	frame_data 5, 4, 0, 0
	frame_data 6, 4, 0, 0
	frame_data 7, 16, 0, 0
	frame_data 7, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable51::
	dw .data_af391
	dw .data_af422
	dw .data_af4bb
	dw .data_af554
	dw .data_af5e5
	dw .data_af676
	dw .data_af707
	dw .data_af798

.data_af391
	db 36 ; size
	db -40, -24, 0, $0
	db -40, -16, 1, $0
	db -40, -8, 2, $0
	db -40, 0, 3, $0
	db -40, 8, 4, $0
	db -40, 16, 0, OAM_XFLIP
	db -32, -24, 5, $0
	db -32, -16, 6, $0
	db -32, -8, 7, $0
	db -32, 0, 8, $0
	db -32, 8, 8, $0
	db -32, 16, 9, $0
	db -24, -24, 10, $0
	db -24, -16, 11, $0
	db -24, -8, 12, $0
	db -24, 0, 8, $0
	db -24, 8, 8, $0
	db -24, 16, 13, $0
	db -16, -24, 14, $0
	db -16, -16, 15, $0
	db -16, -8, 16, $0
	db -16, 0, 17, $0
	db -16, 8, 18, $0
	db -16, 16, 13, OAM_YFLIP
	db -8, -24, 9, OAM_XFLIP | OAM_YFLIP
	db -8, -16, 19, $0
	db -8, -8, 20, $0
	db -8, 0, 21, $0
	db -8, 8, 12, OAM_YFLIP
	db -8, 16, 9, OAM_YFLIP
	db 0, -24, 0, OAM_YFLIP
	db 0, -16, 4, OAM_XFLIP | OAM_YFLIP
	db 0, -8, 22, $0
	db 0, 0, 22, OAM_XFLIP
	db 0, 8, 4, OAM_YFLIP
	db 0, 16, 0, OAM_XFLIP | OAM_YFLIP

.data_af422
	db 38 ; size
	db -40, -24, 0, $0
	db -40, -16, 1, $0
	db -40, -8, 2, $0
	db -40, 0, 3, $0
	db -40, 8, 4, $0
	db -40, 16, 0, OAM_XFLIP
	db -32, -24, 5, $0
	db -32, -16, 6, $0
	db -32, -8, 7, $0
	db -32, 0, 8, $0
	db -32, 8, 8, $0
	db -32, 16, 9, $0
	db -24, -24, 10, $0
	db -24, -16, 11, $0
	db -24, -8, 12, $0
	db -24, 0, 8, $0
	db -24, 8, 8, $0
	db -24, 16, 13, $0
	db -16, -24, 14, $0
	db -16, -16, 15, $0
	db -16, -8, 16, $0
	db -16, 0, 17, $0
	db -16, 8, 18, $0
	db -16, 16, 13, OAM_YFLIP
	db -8, -24, 9, OAM_XFLIP | OAM_YFLIP
	db -8, -16, 19, $0
	db -8, -8, 20, $0
	db -8, 0, 21, $0
	db -8, 8, 12, OAM_YFLIP
	db -8, 16, 9, OAM_YFLIP
	db 0, -8, 22, $0
	db 0, 8, 24, $0
	db 0, 16, 25, $0
	db 0, 21, 26, $0
	db 0, -29, 26, OAM_XFLIP
	db 0, -16, 24, OAM_XFLIP
	db 0, -24, 25, OAM_XFLIP
	db 0, 0, 23, $0

.data_af4bb
	db 38 ; size
	db -44, -24, 0, $0
	db -44, -16, 1, $0
	db -44, -8, 2, $0
	db -44, 0, 3, $0
	db -44, 8, 4, $0
	db -44, 16, 0, OAM_XFLIP
	db -36, -24, 5, $0
	db -36, -16, 6, $0
	db -36, -8, 7, $0
	db -36, 0, 8, $0
	db -36, 8, 8, $0
	db -36, 16, 9, $0
	db -28, -24, 10, $0
	db -28, -16, 11, $0
	db -28, -8, 12, $0
	db -28, 0, 8, $0
	db -28, 8, 8, $0
	db -28, 16, 13, $0
	db -20, -24, 14, $0
	db -20, -16, 15, $0
	db -20, -8, 16, $0
	db -20, 0, 17, $0
	db -20, 8, 18, $0
	db -20, 16, 13, OAM_YFLIP
	db -12, -24, 9, OAM_XFLIP | OAM_YFLIP
	db -12, -16, 19, $0
	db -12, -8, 20, $0
	db -12, 0, 21, $0
	db -12, 8, 12, OAM_YFLIP
	db -12, 16, 9, OAM_YFLIP
	db -4, -24, 0, OAM_YFLIP
	db -4, -16, 4, OAM_XFLIP | OAM_YFLIP
	db -4, 8, 4, OAM_YFLIP
	db -4, 16, 0, OAM_XFLIP | OAM_YFLIP
	db -2, -36, 26, OAM_XFLIP
	db -2, 28, 26, $0
	db -4, 0, 23, $0
	db -4, -8, 23, OAM_XFLIP

.data_af554
	db 36 ; size
	db -40, -24, 0, $0
	db -40, -16, 1, $0
	db -40, -8, 2, $0
	db -40, 0, 3, $0
	db -40, 8, 4, $0
	db -40, 16, 0, OAM_XFLIP
	db -32, -24, 5, $0
	db -32, -16, 6, $0
	db -32, -8, 7, $0
	db -32, 0, 8, $0
	db -32, 8, 8, $0
	db -32, 16, 9, $0
	db -24, -24, 10, $0
	db -24, -16, 11, $0
	db -24, -8, 12, $0
	db -24, 0, 8, $0
	db -24, 8, 8, $0
	db -24, 16, 13, $0
	db -16, -24, 14, $0
	db -16, -16, 15, $0
	db -16, -8, 16, $0
	db -16, 0, 17, $0
	db -16, 8, 18, $0
	db -16, 16, 13, OAM_YFLIP
	db -8, -24, 9, OAM_XFLIP | OAM_YFLIP
	db -8, -16, 19, $0
	db -8, 16, 9, OAM_YFLIP
	db 0, -24, 0, OAM_YFLIP
	db 0, -16, 4, OAM_XFLIP | OAM_YFLIP
	db 0, 8, 4, OAM_YFLIP
	db 0, 16, 0, OAM_XFLIP | OAM_YFLIP
	db -8, -8, 27, $0
	db -8, 0, 28, $0
	db -8, 8, 29, $0
	db 0, -8, 30, $0
	db 0, 0, 31, $0

.data_af5e5
	db 36 ; size
	db -40, -24, 0, $0
	db -40, -16, 1, $0
	db -40, 8, 4, $0
	db -40, 16, 0, OAM_XFLIP
	db -32, -24, 5, $0
	db -32, 8, 8, $0
	db -32, 16, 9, $0
	db -24, -24, 10, $0
	db -24, 0, 8, $0
	db -24, 8, 8, $0
	db -24, 16, 13, $0
	db -16, -24, 14, $0
	db -16, 16, 13, OAM_YFLIP
	db -8, -24, 9, OAM_XFLIP | OAM_YFLIP
	db -8, 16, 9, OAM_YFLIP
	db 0, -24, 0, OAM_YFLIP
	db 0, -16, 4, OAM_XFLIP | OAM_YFLIP
	db 0, 8, 4, OAM_YFLIP
	db 0, 16, 0, OAM_XFLIP | OAM_YFLIP
	db -40, -8, 32, $0
	db -40, 0, 33, $0
	db -32, -16, 34, $0
	db -32, -8, 35, $0
	db -32, 0, 36, $0
	db -24, -16, 37, $0
	db -24, -8, 8, $0
	db -16, -16, 38, $0
	db -16, -8, 39, $0
	db -16, 0, 40, $0
	db -16, 8, 41, $0
	db -8, -16, 42, $0
	db -8, -8, 43, $0
	db -8, 0, 44, $0
	db -8, 8, 45, $0
	db 0, -8, 46, $0
	db 0, 0, 47, $0

.data_af676
	db 36 ; size
	db -40, -24, 0, $0
	db -40, -16, 1, $0
	db -40, 8, 4, $0
	db -40, 16, 0, OAM_XFLIP
	db -32, -24, 5, $0
	db -32, 8, 8, $0
	db -32, 16, 9, $0
	db -24, -24, 10, $0
	db -24, 0, 8, $0
	db -24, 8, 8, $0
	db -24, 16, 13, $0
	db -16, -24, 14, $0
	db -16, 16, 13, OAM_YFLIP
	db -8, -24, 9, OAM_XFLIP | OAM_YFLIP
	db -8, 16, 9, OAM_YFLIP
	db 0, -24, 0, OAM_YFLIP
	db 0, 8, 4, OAM_YFLIP
	db 0, 16, 0, OAM_XFLIP | OAM_YFLIP
	db -40, 0, 33, $0
	db -40, -8, 48, $0
	db -32, -16, 49, $0
	db -32, -8, 50, $0
	db -32, 0, 51, $0
	db -24, -16, 52, $0
	db -24, -8, 53, $0
	db -16, -16, 54, $0
	db -16, -8, 55, $0
	db -16, 0, 56, $0
	db -16, 8, 8, $0
	db -8, -16, 57, $0
	db -8, -8, 58, $0
	db -8, 0, 59, $0
	db -8, 8, 60, $0
	db 0, -8, 62, $0
	db 0, 0, 63, $0
	db 0, -16, 61, $0

.data_af707
	db 36 ; size
	db -40, -24, 0, $0
	db -40, -16, 1, $0
	db -40, 8, 4, $0
	db -40, 16, 0, OAM_XFLIP
	db -32, -24, 5, $0
	db -32, 8, 8, $0
	db -32, 16, 9, $0
	db -24, -24, 10, $0
	db -24, 0, 8, $0
	db -24, 8, 8, $0
	db -24, 16, 13, $0
	db -16, -24, 14, $0
	db -16, 16, 13, OAM_YFLIP
	db -8, -24, 9, OAM_XFLIP | OAM_YFLIP
	db -8, 16, 9, OAM_YFLIP
	db 0, -24, 0, OAM_YFLIP
	db 0, 16, 0, OAM_XFLIP | OAM_YFLIP
	db -40, 0, 33, $0
	db -40, -8, 48, $0
	db -32, -16, 49, $0
	db -16, 8, 8, $0
	db 0, -8, 62, $0
	db 0, 0, 63, $0
	db 0, -16, 61, $0
	db -32, -8, 12, OAM_YFLIP
	db -32, 0, 8, $0
	db -24, -16, 8, $0
	db -24, -8, 8, $0
	db -16, -16, 64, $0
	db -16, -8, 65, $0
	db -16, 0, 8, $0
	db -8, -16, 66, $0
	db -8, -8, 67, $0
	db -8, 0, 68, $0
	db -8, 8, 69, $0
	db 0, 8, 70, $0

.data_af798
	db 36 ; size
	db -40, -24, 0, $0
	db -40, -16, 1, $0
	db -40, 8, 4, $0
	db -40, 16, 0, OAM_XFLIP
	db -32, -24, 5, $0
	db -32, 8, 8, $0
	db -32, 16, 9, $0
	db -24, -24, 10, $0
	db -24, 0, 8, $0
	db -24, 8, 8, $0
	db -24, 16, 13, $0
	db -16, -24, 14, $0
	db -16, 16, 13, OAM_YFLIP
	db -8, -24, 9, OAM_XFLIP | OAM_YFLIP
	db -8, 16, 9, OAM_YFLIP
	db 0, -24, 0, OAM_YFLIP
	db 0, 16, 0, OAM_XFLIP | OAM_YFLIP
	db -40, 0, 33, $0
	db -40, -8, 48, $0
	db -32, -16, 49, $0
	db -16, 8, 8, $0
	db 0, -8, 62, $0
	db 0, 0, 63, $0
	db 0, -16, 61, $0
	db -32, -8, 12, OAM_YFLIP
	db -32, 0, 8, $0
	db -24, -16, 8, $0
	db -24, -8, 8, $0
	db -16, 0, 8, $0
	db -8, 8, 69, $0
	db 0, 8, 70, $0
	db -16, -16, 71, $0
	db -16, -8, 72, $0
	db -8, -16, 73, $0
	db -8, -8, 74, $0
	db -8, 0, 75, $0

AnimData128::
	frame_table AnimFrameTable52
	frame_data 0, 3, 0, 0
	frame_data 1, 5, 0, 0
	frame_data 2, 8, 0, 0
	frame_data 3, 3, 0, 0
	frame_data 4, 5, 0, 0
	frame_data 5, 6, 0, 0
	frame_data 6, 3, 0, 0
	frame_data 7, 5, 0, 0
	frame_data 8, 16, 0, 0
	frame_data 8, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable52::
	dw .data_af86a
	dw .data_af87f
	dw .data_af8a0
	dw .data_af8ad
	dw .data_af8ce
	dw .data_af8fb
	dw .data_af914
	dw .data_af941
	dw .data_af97a

.data_af86a
	db 5 ; size
	db -9, -24, 3, OAM_YFLIP
	db -9, -16, 4, OAM_YFLIP
	db -17, -16, 6, OAM_YFLIP
	db -25, -24, 7, OAM_YFLIP
	db -17, -24, 5, OAM_YFLIP

.data_af87f
	db 8 ; size
	db -9, -24, 3, OAM_YFLIP
	db -9, -16, 4, OAM_YFLIP
	db -17, -16, 6, OAM_YFLIP
	db -25, -24, 7, OAM_YFLIP
	db -17, -24, 5, OAM_YFLIP
	db -13, -23, 0, OAM_YFLIP
	db -21, -23, 2, OAM_YFLIP
	db -21, -31, 1, OAM_YFLIP

.data_af8a0
	db 3 ; size
	db -13, -23, 0, OAM_YFLIP
	db -21, -23, 2, OAM_YFLIP
	db -21, -31, 1, OAM_YFLIP

.data_af8ad
	db 8 ; size
	db 8, 16, 3, OAM_XFLIP | OAM_YFLIP
	db 8, 8, 4, OAM_XFLIP | OAM_YFLIP
	db 0, 8, 6, OAM_XFLIP | OAM_YFLIP
	db -8, 16, 7, OAM_XFLIP | OAM_YFLIP
	db 0, 16, 5, OAM_XFLIP | OAM_YFLIP
	db -13, -23, 0, OAM_YFLIP
	db -21, -23, 2, OAM_YFLIP
	db -21, -31, 1, OAM_YFLIP

.data_af8ce
	db 11 ; size
	db 8, 16, 3, OAM_XFLIP | OAM_YFLIP
	db 8, 8, 4, OAM_XFLIP | OAM_YFLIP
	db 0, 8, 6, OAM_XFLIP | OAM_YFLIP
	db -8, 16, 7, OAM_XFLIP | OAM_YFLIP
	db 0, 16, 5, OAM_XFLIP | OAM_YFLIP
	db -13, -23, 0, OAM_YFLIP
	db -21, -23, 2, OAM_YFLIP
	db -21, -31, 1, OAM_YFLIP
	db 8, 24, 1, OAM_XFLIP
	db 0, 16, 0, OAM_XFLIP
	db 8, 16, 2, OAM_XFLIP

.data_af8fb
	db 6 ; size
	db 8, 24, 1, OAM_XFLIP
	db 0, 16, 0, OAM_XFLIP
	db 8, 16, 2, OAM_XFLIP
	db -13, -23, 0, OAM_YFLIP
	db -21, -23, 2, OAM_YFLIP
	db -21, -31, 1, OAM_YFLIP

.data_af914
	db 11 ; size
	db 2, -17, 3, $0
	db 2, -9, 4, $0
	db 10, -9, 6, $0
	db 10, -17, 5, $0
	db 18, -17, 7, $0
	db 8, 24, 1, OAM_XFLIP
	db 0, 16, 0, OAM_XFLIP
	db 8, 16, 2, OAM_XFLIP
	db -13, -23, 0, OAM_YFLIP
	db -21, -23, 2, OAM_YFLIP
	db -21, -31, 1, OAM_YFLIP

.data_af941
	db 14 ; size
	db 2, -17, 3, $0
	db 2, -9, 4, $0
	db 10, -9, 6, $0
	db 10, -17, 5, $0
	db 8, 24, 1, OAM_XFLIP
	db 0, 16, 0, OAM_XFLIP
	db 8, 16, 2, OAM_XFLIP
	db 18, -17, 7, $0
	db 5, -16, 0, $0
	db 13, -16, 2, $0
	db 13, -24, 1, $0
	db -13, -23, 0, OAM_YFLIP
	db -21, -23, 2, OAM_YFLIP
	db -21, -31, 1, OAM_YFLIP

.data_af97a
	db 9 ; size
	db 8, 24, 1, OAM_XFLIP
	db 0, 16, 0, OAM_XFLIP
	db 8, 16, 2, OAM_XFLIP
	db 5, -16, 0, $0
	db 13, -16, 2, $0
	db 13, -24, 1, $0
	db -13, -23, 0, OAM_YFLIP
	db -21, -23, 2, OAM_YFLIP
	db -21, -31, 1, OAM_YFLIP

AnimData129::
	frame_table AnimFrameTable53
	frame_data 0, 5, 0, 0
	frame_data 1, 5, 0, 0
	frame_data 2, 5, 0, 0
	frame_data 3, 5, 0, 0
	frame_data 4, 4, 0, 0
	frame_data 5, 4, 0, 0
	frame_data 6, 4, 0, 0
	frame_data 7, 4, 0, 0
	frame_data 4, 4, 0, 0
	frame_data 5, 4, 0, 0
	frame_data 6, 4, 0, 0
	frame_data 7, 4, 0, 0
	frame_data 4, 4, 0, 0
	frame_data 5, 4, 0, 0
	frame_data 6, 4, 0, 0
	frame_data 3, 5, 0, 0
	frame_data 2, 5, 0, 0
	frame_data 1, 5, 0, 0
	frame_data 0, 5, 0, 0
	frame_data 0, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable53::
	dw .data_afa06
	dw .data_afa47
	dw .data_afac8
	dw .data_afb69
	dw .data_afc0a
	dw .data_afcab
	dw .data_afd4c
	dw .data_afded

.data_afa06
	db 16 ; size
	db -10, -32, 0, $0
	db -10, -24, 0, OAM_XFLIP
	db -6, -16, 0, OAM_XFLIP
	db -6, -8, 0, $0
	db -10, 8, 0, OAM_XFLIP
	db -10, 0, 0, $0
	db -6, 16, 0, OAM_XFLIP
	db -6, 24, 0, $0
	db -2, -32, 6, OAM_XFLIP
	db -2, -24, 6, $0
	db 2, -16, 6, $0
	db 2, -8, 6, OAM_XFLIP
	db -2, 0, 6, OAM_XFLIP
	db -2, 8, 6, $0
	db 1, 16, 6, $0
	db 1, 24, 6, OAM_XFLIP

.data_afa47
	db 32 ; size
	db -14, -32, 0, $0
	db -6, -32, 1, $0
	db 2, -32, 5, OAM_XFLIP
	db 10, -32, 6, OAM_XFLIP
	db -18, -24, 0, $0
	db -10, -24, 1, $0
	db -2, -24, 5, OAM_XFLIP
	db 6, -24, 6, OAM_XFLIP
	db -18, -16, 0, OAM_XFLIP
	db -10, -16, 1, OAM_XFLIP
	db -2, -16, 5, $0
	db 6, -16, 6, $0
	db -14, -8, 0, OAM_XFLIP
	db -6, -8, 1, OAM_XFLIP
	db 2, -8, 5, $0
	db 10, -8, 6, $0
	db -14, 0, 0, $0
	db -6, 0, 1, $0
	db 2, 0, 5, OAM_XFLIP
	db 10, 0, 6, OAM_XFLIP
	db -18, 8, 0, $0
	db -10, 8, 1, $0
	db -2, 8, 5, OAM_XFLIP
	db 6, 8, 6, OAM_XFLIP
	db -18, 16, 0, OAM_XFLIP
	db -10, 16, 1, OAM_XFLIP
	db -2, 16, 5, $0
	db 6, 16, 6, $0
	db -14, 24, 0, OAM_XFLIP
	db -6, 24, 1, OAM_XFLIP
	db 2, 24, 5, $0
	db 10, 24, 6, $0

.data_afac8
	db 40 ; size
	db -18, -32, 0, OAM_XFLIP
	db -10, -32, 1, OAM_XFLIP
	db -2, -32, 3, $0
	db 6, -32, 5, OAM_XFLIP
	db 14, -32, 6, OAM_XFLIP
	db -18, -24, 0, $0
	db -10, -24, 1, $0
	db -2, -24, 3, $0
	db 6, -24, 5, $0
	db 14, -24, 6, $0
	db -22, -16, 0, $0
	db -14, -16, 1, $0
	db -6, -16, 3, $0
	db 2, -16, 5, $0
	db 10, -16, 6, $0
	db -22, -8, 0, OAM_XFLIP
	db -14, -8, 1, OAM_XFLIP
	db -6, -8, 3, $0
	db 2, -8, 5, OAM_XFLIP
	db 10, -8, 6, OAM_XFLIP
	db -18, 0, 0, OAM_XFLIP
	db -10, 0, 1, OAM_XFLIP
	db -2, 0, 3, $0
	db 6, 0, 5, OAM_XFLIP
	db 14, 0, 6, OAM_XFLIP
	db -18, 8, 0, $0
	db -10, 8, 1, $0
	db -2, 8, 3, $0
	db 6, 8, 5, $0
	db 14, 8, 6, $0
	db -22, 16, 0, $0
	db -14, 16, 1, $0
	db -6, 16, 3, $0
	db 2, 16, 5, $0
	db 10, 16, 6, $0
	db -22, 24, 0, OAM_XFLIP
	db -14, 24, 1, OAM_XFLIP
	db -6, 24, 3, $0
	db 2, 24, 5, OAM_XFLIP
	db 10, 24, 6, OAM_XFLIP

.data_afb69
	db 40 ; size
	db -6, -32, 3, $0
	db -14, -32, 2, OAM_XFLIP
	db -22, -32, 0, OAM_XFLIP
	db 2, -32, 4, $0
	db 10, -32, 6, $0
	db -2, -24, 3, $0
	db -10, -24, 2, OAM_XFLIP
	db -18, -24, 0, OAM_XFLIP
	db 6, -24, 4, $0
	db 14, -24, 6, $0
	db -2, -16, 3, $0
	db -10, -16, 2, $0
	db -18, -16, 0, $0
	db 6, -16, 4, OAM_XFLIP
	db 14, -16, 6, OAM_XFLIP
	db -6, -8, 3, $0
	db -14, -8, 2, $0
	db -22, -8, 0, $0
	db 2, -8, 4, OAM_XFLIP
	db 10, -8, 6, OAM_XFLIP
	db -6, 0, 3, $0
	db -14, 0, 2, OAM_XFLIP
	db -22, 0, 0, OAM_XFLIP
	db 2, 0, 4, $0
	db 10, 0, 6, $0
	db -2, 8, 3, $0
	db -10, 8, 2, OAM_XFLIP
	db -18, 8, 0, OAM_XFLIP
	db 6, 8, 4, $0
	db 14, 8, 6, $0
	db -2, 16, 3, $0
	db -10, 16, 2, $0
	db -18, 16, 0, $0
	db 6, 16, 4, OAM_XFLIP
	db 14, 16, 6, OAM_XFLIP
	db -6, 24, 3, $0
	db -14, 24, 2, $0
	db -22, 24, 0, $0
	db 2, 24, 4, OAM_XFLIP
	db 10, 24, 6, OAM_XFLIP

.data_afc0a
	db 40 ; size
	db -22, -32, 1, $0
	db -14, -32, 2, $0
	db -6, -32, 3, $0
	db 2, -32, 4, $0
	db 10, -32, 5, $0
	db -18, -16, 1, OAM_XFLIP
	db -10, -16, 2, OAM_XFLIP
	db -6, -24, 3, $0
	db 2, -24, 4, OAM_XFLIP
	db 10, -24, 5, OAM_XFLIP
	db -22, -24, 1, OAM_XFLIP
	db -14, -24, 2, OAM_XFLIP
	db -2, -16, 3, $0
	db 6, -16, 4, OAM_XFLIP
	db 14, -16, 5, OAM_XFLIP
	db -18, -8, 1, $0
	db -10, -8, 2, $0
	db -2, -8, 3, $0
	db 6, -8, 4, $0
	db 14, -8, 5, $0
	db -22, 0, 1, $0
	db -14, 0, 2, $0
	db -6, 0, 3, $0
	db 2, 0, 4, $0
	db 10, 0, 5, $0
	db -18, 16, 1, OAM_XFLIP
	db -10, 16, 2, OAM_XFLIP
	db -6, 8, 3, $0
	db 2, 8, 4, OAM_XFLIP
	db 10, 8, 5, OAM_XFLIP
	db -22, 8, 1, OAM_XFLIP
	db -14, 8, 2, OAM_XFLIP
	db -2, 16, 3, $0
	db 6, 16, 4, OAM_XFLIP
	db 14, 16, 5, OAM_XFLIP
	db -18, 24, 1, $0
	db -10, 24, 2, $0
	db -2, 24, 3, $0
	db 6, 24, 4, $0
	db 14, 24, 5, $0

.data_afcab
	db 40 ; size
	db -22, -24, 1, $0
	db -14, -24, 2, $0
	db -6, -24, 3, $0
	db 2, -24, 4, $0
	db 10, -24, 5, $0
	db -18, -8, 1, OAM_XFLIP
	db -10, -8, 2, OAM_XFLIP
	db -6, -16, 3, $0
	db 2, -16, 4, OAM_XFLIP
	db 10, -16, 5, OAM_XFLIP
	db -22, -16, 1, OAM_XFLIP
	db -14, -16, 2, OAM_XFLIP
	db -2, -8, 3, $0
	db 6, -8, 4, OAM_XFLIP
	db 14, -8, 5, OAM_XFLIP
	db -18, 0, 1, $0
	db -10, 0, 2, $0
	db -2, 0, 3, $0
	db 6, 0, 4, $0
	db 14, 0, 5, $0
	db -22, 8, 1, $0
	db -14, 8, 2, $0
	db -6, 8, 3, $0
	db 2, 8, 4, $0
	db 10, 8, 5, $0
	db -18, 24, 1, OAM_XFLIP
	db -10, 24, 2, OAM_XFLIP
	db -6, 16, 3, $0
	db 2, 16, 4, OAM_XFLIP
	db 10, 16, 5, OAM_XFLIP
	db -22, 16, 1, OAM_XFLIP
	db -14, 16, 2, OAM_XFLIP
	db -2, 24, 3, $0
	db 6, 24, 4, OAM_XFLIP
	db 14, 24, 5, OAM_XFLIP
	db -18, -32, 1, $0
	db -10, -32, 2, $0
	db -2, -32, 3, $0
	db 6, -32, 4, $0
	db 14, -32, 5, $0

.data_afd4c
	db 40 ; size
	db -22, -16, 1, $0
	db -14, -16, 2, $0
	db -6, -16, 3, $0
	db 2, -16, 4, $0
	db 10, -16, 5, $0
	db -18, 0, 1, OAM_XFLIP
	db -10, 0, 2, OAM_XFLIP
	db -6, -8, 3, $0
	db 2, -8, 4, OAM_XFLIP
	db 10, -8, 5, OAM_XFLIP
	db -22, -8, 1, OAM_XFLIP
	db -14, -8, 2, OAM_XFLIP
	db -2, 0, 3, $0
	db 6, 0, 4, OAM_XFLIP
	db 14, 0, 5, OAM_XFLIP
	db -18, 8, 1, $0
	db -10, 8, 2, $0
	db -2, 8, 3, $0
	db 6, 8, 4, $0
	db 14, 8, 5, $0
	db -22, 16, 1, $0
	db -14, 16, 2, $0
	db -6, 16, 3, $0
	db 2, 16, 4, $0
	db 10, 16, 5, $0
	db -6, 24, 3, $0
	db 2, 24, 4, OAM_XFLIP
	db 10, 24, 5, OAM_XFLIP
	db -22, 24, 1, OAM_XFLIP
	db -14, 24, 2, OAM_XFLIP
	db -18, -24, 1, $0
	db -10, -24, 2, $0
	db -2, -24, 3, $0
	db 6, -24, 4, $0
	db 14, -24, 5, $0
	db -18, -32, 1, OAM_XFLIP
	db -10, -32, 2, OAM_XFLIP
	db -2, -32, 3, $0
	db 6, -32, 4, OAM_XFLIP
	db 14, -32, 5, OAM_XFLIP

.data_afded
	db 40 ; size
	db -22, -8, 1, $0
	db -14, -8, 2, $0
	db -6, -8, 3, $0
	db 2, -8, 4, $0
	db 10, -8, 5, $0
	db -18, 8, 1, OAM_XFLIP
	db -10, 8, 2, OAM_XFLIP
	db -6, 0, 3, $0
	db 2, 0, 4, OAM_XFLIP
	db 10, 0, 5, OAM_XFLIP
	db -22, 0, 1, OAM_XFLIP
	db -14, 0, 2, OAM_XFLIP
	db -2, 8, 3, $0
	db 6, 8, 4, OAM_XFLIP
	db 14, 8, 5, OAM_XFLIP
	db -18, 16, 1, $0
	db -10, 16, 2, $0
	db -2, 16, 3, $0
	db 6, 16, 4, $0
	db 14, 16, 5, $0
	db -22, 24, 1, $0
	db -14, 24, 2, $0
	db -6, 24, 3, $0
	db 2, 24, 4, $0
	db 10, 24, 5, $0
	db -18, -16, 1, $0
	db -10, -16, 2, $0
	db -2, -16, 3, $0
	db 6, -16, 4, $0
	db 14, -16, 5, $0
	db -18, -24, 1, OAM_XFLIP
	db -10, -24, 2, OAM_XFLIP
	db -2, -24, 3, $0
	db 6, -24, 4, OAM_XFLIP
	db 14, -24, 5, OAM_XFLIP
	db -6, -32, 3, $0
	db 2, -32, 4, OAM_XFLIP
	db 10, -32, 5, OAM_XFLIP
	db -22, -32, 1, OAM_XFLIP
	db -14, -32, 2, OAM_XFLIP

AnimData130::
	frame_table AnimFrameTable54
	frame_data 0, 8, 0, -4
	frame_data 0, 8, 1, 4
	frame_data 1, 8, -1, -4
	frame_data 1, 8, 0, 4
	frame_data 2, 8, 1, -4
	frame_data 2, 8, -1, 4
	frame_data 3, 8, 1, -4
	frame_data 3, 8, -1, 4
	frame_data 4, 8, 1, -4
	frame_data 4, 8, -1, 4
	frame_data 5, 8, 1, -4
	frame_data 5, 8, -1, 4
	frame_data 6, 8, 2, -4
	frame_data 6, 8, -2, 4
	frame_data 7, 8, 1, -4
	frame_data 7, 8, -1, 4
	frame_data 7, 8, 2, 4
	frame_data 7, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimFrameTable54::
	dw .data_afeed
	dw .data_afefe
	dw .data_aff17
	dw .data_aff38
	dw .data_aff5d
	dw .data_aff7e
	dw .data_aff9b
	dw .data_affb0

.data_afeed
	db 4 ; size
	db -24, -8, 0, $0
	db -24, 24, 0, $0
	db -16, 8, 0, $0
	db -16, -30, 0, $0

.data_afefe
	db 6 ; size
	db -16, 0, 0, $0
	db -21, -16, 0, $0
	db -26, 16, 0, $0
	db -16, 28, 0, $0
	db -8, 8, 0, $0
	db -8, -32, 0, $0

.data_aff17
	db 8 ; size
	db -8, 4, 0, $0
	db -13, -22, 0, $0
	db -20, 20, 0, $0
	db -8, 24, 0, $0
	db -24, -8, 0, $0
	db 0, 0, 0, $0
	db -3, -26, 0, $0
	db -24, -24, 0, $0

.data_aff38
	db 9 ; size
	db 5, 2, 0, $0
	db -5, -24, 0, $0
	db -13, 23, 0, $0
	db 0, 20, 0, $0
	db -16, -4, 0, $0
	db 8, -8, 0, $0
	db 0, -24, 0, $0
	db -18, -16, 0, $0
	db -24, 8, 0, $0

.data_aff5d
	db 8 ; size
	db 16, -2, 0, $0
	db 10, -22, 0, $0
	db -1, 18, 0, $0
	db 8, 20, 0, OAM_YFLIP
	db -8, -8, 0, $0
	db 4, -28, 0, $0
	db -12, -20, 0, $0
	db -16, 11, 0, $0

.data_aff7e
	db 7 ; size
	db 9, 13, 0, $0
	db 16, 18, 0, $0
	db 0, -8, 0, $0
	db 16, -16, 0, $0
	db -4, -22, 0, $0
	db -8, 8, 0, $0
	db 8, -32, 0, $0

.data_aff9b
	db 5 ; size
	db 8, -4, 0, $0
	db 19, 16, 0, $0
	db 0, -24, 0, $0
	db 0, 4, 0, $0
	db 12, -32, 0, $0

.data_affb0
	db 4 ; size
	db 16, 0, 0, $0
	db 8, -20, 0, $0
	db 8, 8, 0, $0
	db 16, -32, 0, $0

AnimData150::
	frame_table AnimFrameTable71
	frame_data 2, 8, 0, 0
	frame_data 3, 8, 0, 0
	frame_data 4, 8, 0, 0
	frame_data 5, 8, 0, 0
	frame_data 5, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimData162::
	frame_table AnimFrameTable78
	frame_data 0, 6, 0, 0
	frame_data 23, 6, 0, 0
	frame_data 24, 6, 0, 0
	frame_data 24, -1, 0, 0
	frame_data 0, 0, 0, 0

AnimData166::
	frame_table AnimFrameTable78
	frame_data 0, 1, 0, 0
	frame_data 0, 0, 0, 0
