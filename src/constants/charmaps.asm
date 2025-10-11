; control characters
	charmap "<RAMNAME>", TX_RAM1
	charmap "<RAMTEXT>", TX_RAM2
	charmap "<RAMNUM>",  TX_RAM3

; half-width font ($20-$7e is ascii)
	charmap "\n", $0a ; new line
	charmap " ", $20 ; space
	charmap "!", $21 ; exclamation mark
	charmap "”", $22 ; double quotation mark
	charmap "≠", $23 ; not equal (# won't fit)
	charmap "$", $24 ; dollar sign
	charmap "%", $25 ; percent sign
	charmap "&", $26 ; ampersand (this is actually a large lowercase epsilon ε)
	charmap "'", $27 ; apostrophe/right single quotation mark
	charmap "(", $28 ; open parenthesis
	charmap ")", $29 ; close parenthesis
	charmap "*", $2a ; asterisk (this is actually a multiplication symbol ×)
	charmap "+", $2b ; plus
	charmap ",", $2c ; comma
	charmap "-", $2d ; hyphen/minus
	charmap ".", $2e ; period
	charmap "/", $2f ; slash/divide
	charmap "0", $30
	charmap "1", $31
	charmap "2", $32
	charmap "3", $33
	charmap "4", $34
	charmap "5", $35
	charmap "6", $36
	charmap "7", $37
	charmap "8", $38
	charmap "9", $39
	charmap ":", $3a ; colon
	charmap ";", $3b ; semicolon
	charmap "‹", $3c ; less than/open angled bracket (<)
	charmap "=", $3d ; equals
	charmap ">", $3e ; greater than/close angled bracket
	charmap "?", $3f ; question mark
	charmap "′", $40; prime symbol (@ won't fit)
	charmap "A", $41
	charmap "B", $42
	charmap "C", $43
	charmap "D", $44
	charmap "E", $45
	charmap "F", $46
	charmap "G", $47
	charmap "H", $48
	charmap "I", $49
	charmap "J", $4a
	charmap "K", $4b
	charmap "L", $4c
	charmap "M", $4d
	charmap "N", $4e
	charmap "O", $4f
	charmap "P", $50
	charmap "Q", $51
	charmap "R", $52
	charmap "S", $53
	charmap "T", $54
	charmap "U", $55
	charmap "V", $56
	charmap "W", $57
	charmap "X", $58
	charmap "Y", $59
	charmap "Z", $5a
	charmap "[", $5b ; opening bracket
	charmap "\\", $5c ; backslash
	charmap "]", $5d ; closing bracket
	charmap "^", $5e ; caret
	charmap "_", $5f ; underscore
	charmap "`", $60 ; backtick
	charmap "a", $61
	charmap "b", $62
	charmap "c", $63
	charmap "d", $64
	charmap "e", $65
	charmap "f", $66
	charmap "g", $67
	charmap "h", $68
	charmap "i", $69
	charmap "j", $6a
	charmap "k", $6b
	charmap "l", $6c
	charmap "m", $6d
	charmap "n", $6e
	charmap "o", $6f
	charmap "p", $70
	charmap "q", $71
	charmap "r", $72
	charmap "s", $73
	charmap "t", $74
	charmap "u", $75
	charmap "v", $76
	charmap "w", $77
	charmap "x", $78
	charmap "y", $79
	charmap "z", $7a
	charmap "\{", $7b ; opening brace
	charmap "|", $7c ; vertical bar
	charmap "}", $7d ; closing brace
	charmap "~", $7e ; equivalency sign/tilde
	charmap "■", $7f ; black rectangle (3x7)
	charmap "‘", $80 ; left single quotation mark
	charmap "’", $81 ; right single quotation mark
	charmap "•", $82 ; bullet point
	charmap "°", $83 ; degree symbol
	charmap "￣", $84
;	charmap "", $85
	charmap "♀", $86 ; female symbol
	charmap "♂", $87 ; male symbol
	charmap "[Lv.]", $88, $89 ; Lv. symbol
;	charmap "", $8a
;	charmap "", $8b
;	charmap "", $8c
;	charmap "", $8d
;	charmap "", $8e
;	charmap "", $8f
;	charmap "", $90
;	charmap "", $91
;	charmap "", $92
;	charmap "", $93
;	charmap "", $94
;	charmap "", $95
;	charmap "", $96
;	charmap "", $97
;	charmap "", $98
;	charmap "", $99
;	charmap "", $9a
;	charmap "", $9b
;	charmap "", $9c
;	charmap "", $9d
;	charmap "", $9e
;	charmap "", $9f
;	charmap "", $a0
;	charmap "", $a1
;	charmap "", $a2
;	charmap "", $a3
;	charmap "", $a4
;	charmap "", $a5
;	charmap "", $a6
;	charmap "", $a7
;	charmap "", $a8
;	charmap "", $a9
;	charmap "", $aa
;	charmap "", $ab
;	charmap "", $ac
;	charmap "", $ad
;	charmap "", $ae
;	charmap "", $af
;	charmap "", $b0
;	charmap "", $b1
;	charmap "", $b2
;	charmap "", $b3
;	charmap "", $b4
;	charmap "", $b5
;	charmap "", $b6
;	charmap "", $b7
;	charmap "", $b8
;	charmap "", $b9
;	charmap "", $ba
;	charmap "", $bb
;	charmap "", $bc
;	charmap "", $bd
	charmap "¡", $be ; inverted exclamation mark
	charmap "¿", $bf ; inverted question mark
	charmap "À", $c0 ; A with grave accent
	charmap "Á", $c1 ; A with acute accent
	charmap "Â", $c2 ; A with circumflex
	charmap "Ã", $c3 ; A with tilde
	charmap "Ä", $c4 ; A with diaeresis/umlaut
	charmap "Å", $c5 ; A with overring
;	charmap "", $c6
	charmap "Ç", $c7 ; C with cedilla accent
	charmap "È", $c8 ; E with grave accent
	charmap "É", $c9 ; E with acute accent
	charmap "Ê", $ca ; E with circumflex 
	charmap "Ë", $cb ; E with diaeresis/umlaut
	charmap "Ì", $cc ; I with grave accent
	charmap "Í", $cd ; I with acute accent
	charmap "Î", $ce ; I with circumflex
	charmap "Ï", $cf ; I with diaeresis/umlaut
;	charmap "", $d0
	charmap "Ñ", $d1 ; N with tilde
	charmap "Ò", $d2 ; O with grave accent
	charmap "Ó", $d3 ; O with acute accent
	charmap "Ô", $d4 ; O with circumflex
	charmap "Õ", $d5 ; O with tilde
	charmap "Ö", $d6 ; O with diaeresis/umlaut
;	charmap "", $d7
;	charmap "", $d8
	charmap "Ù", $d9 ; U with grave accent
	charmap "Ú", $da ; U with acute accent
	charmap "Û", $db ; U with circumflex
	charmap "Ü", $dc ; U with diaeresis/umlaut
	charmap "Ý", $dd ; Y with acute accent
	charmap "Ÿ", $de ; Y with diaeresis/umlaut
;	charmap "", $df
	charmap "à", $e0 ; a with grave accent
	charmap "á", $e1 ; a with acute accent
	charmap "â", $e2 ; a with circumflex
	charmap "ã", $e3 ; a with tilde
	charmap "ä", $e4 ; a with diaeresis/umlaut
	charmap "å", $e5 ; a with overring
;	charmap "", $e6
	charmap "ç", $e7 ; c with cedilla
	charmap "è", $e8 ; e with grave accent
	charmap "é", $e9 ; e with acute accent
	charmap "ê", $ea ; e with circumflex
	charmap "ë", $eb ; e with diaeresis/umlaut
	charmap "ì", $ec ; i with grave accent
	charmap "í", $ed ; i with acute accent
	charmap "î", $ee ; i with circumflex
	charmap "ï", $ef ; i with diaeresis/umlaut
;	charmap "", $f0
	charmap "ñ", $f1 ; n with tilde
	charmap "ò", $f2 ; o with grave accent
	charmap "ó", $f3 ; o with acute accent
	charmap "ô", $f4 ; o with circumflex
	charmap "õ", $f5 ; o with tilde
	charmap "ö", $f6 ; o with diaeresis/umlautt
;	charmap "", $f7
;	charmap "", $f8
	charmap "ù", $f9 ; u with grave accent
	charmap "ú", $fa ; u with acute accent
	charmap "û", $fb ; u with circumflex
	charmap "ü", $fc ; u with diaeresis/umlaut
	charmap "ý", $fd ; y with acute accent
	charmap "ÿ", $fe ; y with diaeresis/umlaut

NEWCHARMAP katakana
NEWCHARMAP hiragana
NEWCHARMAP fullwidth

	charmap "<RAMNAME>", TX_RAM1
	charmap "<RAMTEXT>", TX_RAM2
	charmap "<RAMNUM>",  TX_RAM3

MACRO fwcharmap
	IF \1 == TX_KATAKANA
		charmap \2, \3
		PUSHC katakana
		charmap \2, \3
		POPC
	ELIF \1 == TX_HIRAGANA
		charmap \2, \3
		PUSHC hiragana
		charmap \2, \3
		POPC
	ELIF \1 == TX_FULLWIDTH0
		charmap \2, \3
	ELSE
		charmap \2, \1, \3
	ENDC
ENDM

; TX_KATAKANA
	fwcharmap TX_KATAKANA, "ヲ", $10
	fwcharmap TX_KATAKANA, "ア", $11
	fwcharmap TX_KATAKANA, "イ", $12
	fwcharmap TX_KATAKANA, "ウ", $13
	fwcharmap TX_KATAKANA, "エ", $14
	fwcharmap TX_KATAKANA, "オ", $15
	fwcharmap TX_KATAKANA, "カ", $16
	fwcharmap TX_KATAKANA, "キ", $17
	fwcharmap TX_KATAKANA, "ク", $18
	fwcharmap TX_KATAKANA, "ケ", $19
	fwcharmap TX_KATAKANA, "コ", $1a
	fwcharmap TX_KATAKANA, "サ", $1b
	fwcharmap TX_KATAKANA, "シ", $1c
	fwcharmap TX_KATAKANA, "ス", $1d
	fwcharmap TX_KATAKANA, "セ", $1e
	fwcharmap TX_KATAKANA, "ソ", $1f
	fwcharmap TX_KATAKANA, "タ", $20
	fwcharmap TX_KATAKANA, "チ", $21
	fwcharmap TX_KATAKANA, "ツ", $22
	fwcharmap TX_KATAKANA, "テ", $23
	fwcharmap TX_KATAKANA, "ト", $24
	fwcharmap TX_KATAKANA, "ナ", $25
	fwcharmap TX_KATAKANA, "ニ", $26
	fwcharmap TX_KATAKANA, "ヌ", $27
	fwcharmap TX_KATAKANA, "ネ", $28
	fwcharmap TX_KATAKANA, "ノ", $29
	fwcharmap TX_KATAKANA, "ハ", $2a
	fwcharmap TX_KATAKANA, "ヒ", $2b
	fwcharmap TX_KATAKANA, "フ", $2c
	fwcharmap TX_KATAKANA, "ヘ", $2d
	fwcharmap TX_KATAKANA, "ホ", $2e
	fwcharmap TX_KATAKANA, "マ", $2f
	fwcharmap TX_KATAKANA, "ミ", $30
	fwcharmap TX_KATAKANA, "ム", $31
	fwcharmap TX_KATAKANA, "メ", $32
	fwcharmap TX_KATAKANA, "モ", $33
	fwcharmap TX_KATAKANA, "ヤ", $34
	fwcharmap TX_KATAKANA, "ユ", $35
	fwcharmap TX_KATAKANA, "ヨ", $36
	fwcharmap TX_KATAKANA, "ラ", $37
	fwcharmap TX_KATAKANA, "リ", $38
	fwcharmap TX_KATAKANA, "ル", $39
	fwcharmap TX_KATAKANA, "レ", $3a
	fwcharmap TX_KATAKANA, "ロ", $3b
	fwcharmap TX_KATAKANA, "ワ", $3c
	fwcharmap TX_KATAKANA, "ン", $3d
	fwcharmap TX_KATAKANA, "ガ", $3e
	fwcharmap TX_KATAKANA, "ギ", $3f
	fwcharmap TX_KATAKANA, "グ", $40
	fwcharmap TX_KATAKANA, "ゲ", $41
	fwcharmap TX_KATAKANA, "ゴ", $42
	fwcharmap TX_KATAKANA, "ザ", $43
	fwcharmap TX_KATAKANA, "ジ", $44
	fwcharmap TX_KATAKANA, "ズ", $45
	fwcharmap TX_KATAKANA, "ゼ", $46
	fwcharmap TX_KATAKANA, "ゾ", $47
	fwcharmap TX_KATAKANA, "ダ", $48
	fwcharmap TX_KATAKANA, "ヂ", $49
	fwcharmap TX_KATAKANA, "ヅ", $4a
	fwcharmap TX_KATAKANA, "デ", $4b
	fwcharmap TX_KATAKANA, "ド", $4c
	fwcharmap TX_KATAKANA, "バ", $4d
	fwcharmap TX_KATAKANA, "ビ", $4e
	fwcharmap TX_KATAKANA, "ブ", $4f
	fwcharmap TX_KATAKANA, "ベ", $50
	fwcharmap TX_KATAKANA, "ボ", $51
	fwcharmap TX_KATAKANA, "パ", $52
	fwcharmap TX_KATAKANA, "ピ", $53
	fwcharmap TX_KATAKANA, "プ", $54
	fwcharmap TX_KATAKANA, "ペ", $55
	fwcharmap TX_KATAKANA, "ポ", $56
	fwcharmap TX_KATAKANA, "ァ", $57
	fwcharmap TX_KATAKANA, "ィ", $58
	fwcharmap TX_KATAKANA, "ゥ", $59
	fwcharmap TX_KATAKANA, "ェ", $5a
	fwcharmap TX_KATAKANA, "ォ", $5b
	fwcharmap TX_KATAKANA, "ャ", $5c
	fwcharmap TX_KATAKANA, "ュ", $5d
	fwcharmap TX_KATAKANA, "ョ", $5e
	fwcharmap TX_KATAKANA, "ッ", $5f

; TX_HIRAGANA
	fwcharmap TX_HIRAGANA, "を", $10
	fwcharmap TX_HIRAGANA, "あ", $11
	fwcharmap TX_HIRAGANA, "い", $12
	fwcharmap TX_HIRAGANA, "う", $13
	fwcharmap TX_HIRAGANA, "え", $14
	fwcharmap TX_HIRAGANA, "お", $15
	fwcharmap TX_HIRAGANA, "か", $16
	fwcharmap TX_HIRAGANA, "き", $17
	fwcharmap TX_HIRAGANA, "く", $18
	fwcharmap TX_HIRAGANA, "け", $19
	fwcharmap TX_HIRAGANA, "こ", $1a
	fwcharmap TX_HIRAGANA, "さ", $1b
	fwcharmap TX_HIRAGANA, "し", $1c
	fwcharmap TX_HIRAGANA, "す", $1d
	fwcharmap TX_HIRAGANA, "せ", $1e
	fwcharmap TX_HIRAGANA, "そ", $1f
	fwcharmap TX_HIRAGANA, "た", $20
	fwcharmap TX_HIRAGANA, "ち", $21
	fwcharmap TX_HIRAGANA, "つ", $22
	fwcharmap TX_HIRAGANA, "て", $23
	fwcharmap TX_HIRAGANA, "と", $24
	fwcharmap TX_HIRAGANA, "な", $25
	fwcharmap TX_HIRAGANA, "に", $26
	fwcharmap TX_HIRAGANA, "ぬ", $27
	fwcharmap TX_HIRAGANA, "ね", $28
	fwcharmap TX_HIRAGANA, "の", $29
	fwcharmap TX_HIRAGANA, "は", $2a
	fwcharmap TX_HIRAGANA, "ひ", $2b
	fwcharmap TX_HIRAGANA, "ふ", $2c
	fwcharmap TX_HIRAGANA, "へ", $2d
	fwcharmap TX_HIRAGANA, "ほ", $2e
	fwcharmap TX_HIRAGANA, "ま", $2f
	fwcharmap TX_HIRAGANA, "み", $30
	fwcharmap TX_HIRAGANA, "む", $31
	fwcharmap TX_HIRAGANA, "め", $32
	fwcharmap TX_HIRAGANA, "も", $33
	fwcharmap TX_HIRAGANA, "や", $34
	fwcharmap TX_HIRAGANA, "ゆ", $35
	fwcharmap TX_HIRAGANA, "よ", $36
	fwcharmap TX_HIRAGANA, "ら", $37
	fwcharmap TX_HIRAGANA, "り", $38
	fwcharmap TX_HIRAGANA, "る", $39
	fwcharmap TX_HIRAGANA, "れ", $3a
	fwcharmap TX_HIRAGANA, "ろ", $3b
	fwcharmap TX_HIRAGANA, "わ", $3c
	fwcharmap TX_HIRAGANA, "ん", $3d
	fwcharmap TX_HIRAGANA, "が", $3e
	fwcharmap TX_HIRAGANA, "ぎ", $3f
	fwcharmap TX_HIRAGANA, "ぐ", $40
	fwcharmap TX_HIRAGANA, "げ", $41
	fwcharmap TX_HIRAGANA, "ご", $42
	fwcharmap TX_HIRAGANA, "ざ", $43
	fwcharmap TX_HIRAGANA, "じ", $44
	fwcharmap TX_HIRAGANA, "ず", $45
	fwcharmap TX_HIRAGANA, "ぜ", $46
	fwcharmap TX_HIRAGANA, "ぞ", $47
	fwcharmap TX_HIRAGANA, "だ", $48
	fwcharmap TX_HIRAGANA, "ぢ", $49
	fwcharmap TX_HIRAGANA, "づ", $4a
	fwcharmap TX_HIRAGANA, "で", $4b
	fwcharmap TX_HIRAGANA, "ど", $4c
	fwcharmap TX_HIRAGANA, "ば", $4d
	fwcharmap TX_HIRAGANA, "び", $4e
	fwcharmap TX_HIRAGANA, "ぶ", $4f
	fwcharmap TX_HIRAGANA, "べ", $50
	fwcharmap TX_HIRAGANA, "ぼ", $51
	fwcharmap TX_HIRAGANA, "ぱ", $52
	fwcharmap TX_HIRAGANA, "ぴ", $53
	fwcharmap TX_HIRAGANA, "ぷ", $54
	fwcharmap TX_HIRAGANA, "ぺ", $55
	fwcharmap TX_HIRAGANA, "ぽ", $56
	fwcharmap TX_HIRAGANA, "ぁ", $57
	fwcharmap TX_HIRAGANA, "ぃ", $58
	fwcharmap TX_HIRAGANA, "ぅ", $59
	fwcharmap TX_HIRAGANA, "ぇ", $5a
	fwcharmap TX_HIRAGANA, "ぉ", $5b
	fwcharmap TX_HIRAGANA, "ゃ", $5c
	fwcharmap TX_HIRAGANA, "ゅ", $5d
	fwcharmap TX_HIRAGANA, "ょ", $5e
	fwcharmap TX_HIRAGANA, "っ", $5f

; TX_KATAKANA, TX_HIRAGANA, and TX_FULLWIDTH0
	fwcharmap TX_FULLWIDTH0, "º", $60 ; right-aligned 0
	fwcharmap TX_FULLWIDTH0, "¹", $61 ; right-aligned 1
	fwcharmap TX_FULLWIDTH0, "²", $62 ; right-aligned 2
	fwcharmap TX_FULLWIDTH0, "³", $63 ; right-aligned 3
	fwcharmap TX_FULLWIDTH0, "⁴", $64 ; right-aligned 4
	fwcharmap TX_FULLWIDTH0, "⁵", $65 ; right-aligned 5
	fwcharmap TX_FULLWIDTH0, "⁶", $66 ; right-aligned 6
	fwcharmap TX_FULLWIDTH0, "⁷", $67 ; right-aligned 7
	fwcharmap TX_FULLWIDTH0, "⁸", $68 ; right-aligned 8
	fwcharmap TX_FULLWIDTH0, "⁹", $69 ; right-aligned 9
	fwcharmap TX_FULLWIDTH0, "˖", $6a ; right-aligned plus sign
	fwcharmap TX_FULLWIDTH0, "˗", $6b ; right-aligned minus sign
	fwcharmap TX_FULLWIDTH0, "×", $6c ; right-aligned multiplication sign
	fwcharmap TX_FULLWIDTH0, "⁄", $6d ; smaller slash/division
;	fwcharmap TX_FULLWIDTH0, "!", $6e ; duplicate exclamation point
;	fwcharmap TX_FULLWIDTH0, "?", $6f ; duplicate question mark
;	fwcharmap TX_FULLWIDTH0, " ", $70 ; duplicate empty space
	fwcharmap TX_FULLWIDTH0, "﴾", $71 ; alternate/shorter open parenthesis
	fwcharmap TX_FULLWIDTH0, "﴿", $72 ; alternate/shorter close parenthesis
	fwcharmap TX_FULLWIDTH0, "「", $73 ; left quotation mark (Japanese)
	fwcharmap TX_FULLWIDTH0, "」", $74 ; right quotation mark (Japanese)
	fwcharmap TX_FULLWIDTH0, "、", $75 ; comma (Japanese)
	fwcharmap TX_FULLWIDTH0, "。", $76 ; full stop (Japanese)
	fwcharmap TX_FULLWIDTH0, "・", $77 ; interpunct (Japanese)
	fwcharmap TX_FULLWIDTH0, "ー", $78 ; prolonged sound mark (Japanese)
	fwcharmap TX_FULLWIDTH0, "˷", $79 ; wave dash (Japanese)
;	fwcharmap TX_FULLWIDTH0, "", $7a
;	fwcharmap TX_FULLWIDTH0, "", $7b
;	fwcharmap TX_FULLWIDTH0, "", $7c
;	fwcharmap TX_FULLWIDTH0, "", $7d
;	fwcharmap TX_FULLWIDTH0, "", $7e
;	fwcharmap TX_FULLWIDTH0, "", $7f
;	fwcharmap TX_FULLWIDTH0, "", $80
;	fwcharmap TX_FULLWIDTH0, "", $81
;	fwcharmap TX_FULLWIDTH0, "", $82
;	fwcharmap TX_FULLWIDTH0, "", $83
;	fwcharmap TX_FULLWIDTH0, "", $84
;	fwcharmap TX_FULLWIDTH0, "", $85
;	fwcharmap TX_FULLWIDTH0, "", $86
;	fwcharmap TX_FULLWIDTH0, "", $87
;	fwcharmap TX_FULLWIDTH0, "", $88
;	fwcharmap TX_FULLWIDTH0, "", $89
;	fwcharmap TX_FULLWIDTH0, "", $8a
;	fwcharmap TX_FULLWIDTH0, "", $8b
;	fwcharmap TX_FULLWIDTH0, "", $8c
;	fwcharmap TX_FULLWIDTH0, "", $8d
;	fwcharmap TX_FULLWIDTH0, "", $8e
;	fwcharmap TX_FULLWIDTH0, "", $8f
	fwcharmap TX_FULLWIDTH0, "[Lv.]", $90 ; Lv. symbol
;	fwcharmap TX_FULLWIDTH0, "", $91
;	fwcharmap TX_FULLWIDTH0, "", $92
;	fwcharmap TX_FULLWIDTH0, "", $93
;	fwcharmap TX_FULLWIDTH0, "", $94
;	fwcharmap TX_FULLWIDTH0, "", $95
;	fwcharmap TX_FULLWIDTH0, "", $96
;	fwcharmap TX_FULLWIDTH0, "", $97
;	fwcharmap TX_FULLWIDTH0, "", $98
;	fwcharmap TX_FULLWIDTH0, "", $99
;	fwcharmap TX_FULLWIDTH0, "", $9a
;	fwcharmap TX_FULLWIDTH0, "", $9b
	fwcharmap TX_FULLWIDTH0, "•", $9c ; bullet point
	fwcharmap TX_FULLWIDTH0, "꞉", $9d ; centered colon
	fwcharmap TX_FULLWIDTH0, "‘", $9e ; left single quotation mark
	fwcharmap TX_FULLWIDTH0, "“", $9f ; left double quotation Mark
; $a0-$fe ARE OFFSET ASCII CHARACTERS ($20-$7e + $80)
	fwcharmap TX_FULLWIDTH0, " ", $a0 ; space
	fwcharmap TX_FULLWIDTH0, "!", $a1 ; exclamation mark
	fwcharmap TX_FULLWIDTH0, "”", $a2 ; right double quotation mark
	fwcharmap TX_FULLWIDTH0, "#", $a3 ; number sign
	fwcharmap TX_FULLWIDTH0, "$", $a4 ; dollar sign
	fwcharmap TX_FULLWIDTH0, "%", $a5 ; percent sign
	fwcharmap TX_FULLWIDTH0, "&", $a6 ; ampersand
	fwcharmap TX_FULLWIDTH0, "'", $a7 ; apostrophe/right single quotation mark
	fwcharmap TX_FULLWIDTH0, "(", $a8 ; open parenthesis
	fwcharmap TX_FULLWIDTH0, ")", $a9 ; close parenthesis
	fwcharmap TX_FULLWIDTH0, "*", $aa ; asterisk
	fwcharmap TX_FULLWIDTH0, "+", $ab ; plus
	fwcharmap TX_FULLWIDTH0, ",", $ac ; comma
	fwcharmap TX_FULLWIDTH0, "-", $ad ; hyphen/minus (5 pixels long)
	fwcharmap TX_FULLWIDTH0, ".", $ae ; period
	fwcharmap TX_FULLWIDTH0, "/", $af ; larger slash/division
	fwcharmap TX_FULLWIDTH0, "0", $b0 ; left-aligned 0
	fwcharmap TX_FULLWIDTH0, "1", $b1 ; left-aligned 1
	fwcharmap TX_FULLWIDTH0, "2", $b2 ; left-aligned 2
	fwcharmap TX_FULLWIDTH0, "3", $b3 ; left-aligned 3
	fwcharmap TX_FULLWIDTH0, "4", $b4 ; left-aligned 4
	fwcharmap TX_FULLWIDTH0, "5", $b5 ; left-aligned 5
	fwcharmap TX_FULLWIDTH0, "6", $b6 ; left-aligned 6
	fwcharmap TX_FULLWIDTH0, "7", $b7 ; left-aligned 7
	fwcharmap TX_FULLWIDTH0, "8", $b8 ; left-aligned 8
	fwcharmap TX_FULLWIDTH0, "9", $b9 ; left-aligned 9
	fwcharmap TX_FULLWIDTH0, ":", $ba ; colon
	fwcharmap TX_FULLWIDTH0, ";", $bb ; semicolon
	fwcharmap TX_FULLWIDTH0, "<", $bc ; less than/open angled bracket
	fwcharmap TX_FULLWIDTH0, "=", $bd ; equals
	fwcharmap TX_FULLWIDTH0, ">", $be ; greater than/close angled bracket
	fwcharmap TX_FULLWIDTH0, "?", $bf ; question mark
	fwcharmap TX_FULLWIDTH0, "@", $c0 ; at sign
	fwcharmap TX_FULLWIDTH0, "A", $c1
	fwcharmap TX_FULLWIDTH0, "B", $c2
	fwcharmap TX_FULLWIDTH0, "C", $c3
	fwcharmap TX_FULLWIDTH0, "D", $c4
	fwcharmap TX_FULLWIDTH0, "E", $c5
	fwcharmap TX_FULLWIDTH0, "F", $c6
	fwcharmap TX_FULLWIDTH0, "G", $c7
	fwcharmap TX_FULLWIDTH0, "H", $c8
	fwcharmap TX_FULLWIDTH0, "I", $c9
	fwcharmap TX_FULLWIDTH0, "J", $ca
	fwcharmap TX_FULLWIDTH0, "K", $cb
	fwcharmap TX_FULLWIDTH0, "L", $cc
	fwcharmap TX_FULLWIDTH0, "M", $cd
	fwcharmap TX_FULLWIDTH0, "N", $ce
	fwcharmap TX_FULLWIDTH0, "O", $cf
	fwcharmap TX_FULLWIDTH0, "P", $d0
	fwcharmap TX_FULLWIDTH0, "Q", $d1
	fwcharmap TX_FULLWIDTH0, "R", $d2
	fwcharmap TX_FULLWIDTH0, "S", $d3
	fwcharmap TX_FULLWIDTH0, "T", $d4
	fwcharmap TX_FULLWIDTH0, "U", $d5
	fwcharmap TX_FULLWIDTH0, "V", $d6
	fwcharmap TX_FULLWIDTH0, "W", $d7
	fwcharmap TX_FULLWIDTH0, "X", $d8
	fwcharmap TX_FULLWIDTH0, "Y", $d9
	fwcharmap TX_FULLWIDTH0, "Z", $da
	fwcharmap TX_FULLWIDTH0, "[", $db ; opening bracket
	fwcharmap TX_FULLWIDTH0, "\\", $dc ; backslash
	fwcharmap TX_FULLWIDTH0, "]", $dd ; closing bracket
	fwcharmap TX_FULLWIDTH0, "^", $de ; caret
	fwcharmap TX_FULLWIDTH0, "_", $df ; underscore
	fwcharmap TX_FULLWIDTH0, "`", $e0 ; backtick
	fwcharmap TX_FULLWIDTH0, "a", $e1
	fwcharmap TX_FULLWIDTH0, "b", $e2
	fwcharmap TX_FULLWIDTH0, "c", $e3
	fwcharmap TX_FULLWIDTH0, "d", $e4
	fwcharmap TX_FULLWIDTH0, "e", $e5
	fwcharmap TX_FULLWIDTH0, "f", $e6
	fwcharmap TX_FULLWIDTH0, "g", $e7
	fwcharmap TX_FULLWIDTH0, "h", $e8
	fwcharmap TX_FULLWIDTH0, "i", $e9
	fwcharmap TX_FULLWIDTH0, "j", $ea
	fwcharmap TX_FULLWIDTH0, "k", $eb
	fwcharmap TX_FULLWIDTH0, "l", $ec
	fwcharmap TX_FULLWIDTH0, "m", $ed
	fwcharmap TX_FULLWIDTH0, "n", $ee
	fwcharmap TX_FULLWIDTH0, "o", $ef
	fwcharmap TX_FULLWIDTH0, "p", $f0
	fwcharmap TX_FULLWIDTH0, "q", $f1
	fwcharmap TX_FULLWIDTH0, "r", $f2
	fwcharmap TX_FULLWIDTH0, "s", $f3
	fwcharmap TX_FULLWIDTH0, "t", $f4
	fwcharmap TX_FULLWIDTH0, "u", $f5
	fwcharmap TX_FULLWIDTH0, "v", $f6
	fwcharmap TX_FULLWIDTH0, "w", $f7
	fwcharmap TX_FULLWIDTH0, "x", $f8
	fwcharmap TX_FULLWIDTH0, "y", $f9
	fwcharmap TX_FULLWIDTH0, "z", $fa
	fwcharmap TX_FULLWIDTH0, "\{", $fb ; opening brace
	fwcharmap TX_FULLWIDTH0, "|", $fc ; vertical bar
	fwcharmap TX_FULLWIDTH0, "}", $fd ; closing brace
	fwcharmap TX_FULLWIDTH0, "~", $fe ; equivalency sign/tilde

; TX_FULLWIDTH3
; $20-$7e ARE DUPLICATE ASCII CHARACTERS
;	fwcharmap TX_FULLWIDTH3, " ", $20 ; space
;	fwcharmap TX_FULLWIDTH3, "!", $21 ; exclamation mark
;	fwcharmap TX_FULLWIDTH3, "”", $22 ; right double quotation mark
;	fwcharmap TX_FULLWIDTH3, "#", $23 ; number sign
;	fwcharmap TX_FULLWIDTH3, "$", $24 ; dollar sign
;	fwcharmap TX_FULLWIDTH3, "%", $25 ; percent sign
;	fwcharmap TX_FULLWIDTH3, "&", $26 ; ampersand
;	fwcharmap TX_FULLWIDTH3, "'", $27 ; apostrophe/right single quotation mark
;	fwcharmap TX_FULLWIDTH3, "(", $28 ; open parenthesis
;	fwcharmap TX_FULLWIDTH3, ")", $29 ; close parenthesis
;	fwcharmap TX_FULLWIDTH3, "*", $2a ; asterisk
;	fwcharmap TX_FULLWIDTH3, "+", $2b ; plus
;	fwcharmap TX_FULLWIDTH3, ",", $2c ; comma
;	fwcharmap TX_FULLWIDTH3, "-", $2d ; hyphen/minus (5 pixels long)
;	fwcharmap TX_FULLWIDTH3, ".", $2e ; period
;	fwcharmap TX_FULLWIDTH3, "/", $2f ; slash/divide
;	fwcharmap TX_FULLWIDTH3, "0", $30
;	fwcharmap TX_FULLWIDTH3, "1", $31
;	fwcharmap TX_FULLWIDTH3, "2", $32
;	fwcharmap TX_FULLWIDTH3, "3", $33
;	fwcharmap TX_FULLWIDTH3, "4", $34
;	fwcharmap TX_FULLWIDTH3, "5", $35
;	fwcharmap TX_FULLWIDTH3, "6", $36
;	fwcharmap TX_FULLWIDTH3, "7", $37
;	fwcharmap TX_FULLWIDTH3, "8", $38
;	fwcharmap TX_FULLWIDTH3, "9", $39
;	fwcharmap TX_FULLWIDTH3, ":", $3a ; colon
;	fwcharmap TX_FULLWIDTH3, ";", $3b ; semicolon
;	fwcharmap TX_FULLWIDTH3, "<", $3c ; less than/open angled bracket
;	fwcharmap TX_FULLWIDTH3, "=", $3d ; equals
;	fwcharmap TX_FULLWIDTH3, ">", $3e ; greater than/close angled bracket
;	fwcharmap TX_FULLWIDTH3, "?", $3f ; question mark
;	fwcharmap TX_FULLWIDTH3, "@", $40 ; at sign
;	fwcharmap TX_FULLWIDTH3, "A", $41
;	fwcharmap TX_FULLWIDTH3, "B", $42
;	fwcharmap TX_FULLWIDTH3, "C", $43
;	fwcharmap TX_FULLWIDTH3, "D", $44
;	fwcharmap TX_FULLWIDTH3, "E", $45
;	fwcharmap TX_FULLWIDTH3, "F", $46
;	fwcharmap TX_FULLWIDTH3, "G", $47
;	fwcharmap TX_FULLWIDTH3, "H", $48
;	fwcharmap TX_FULLWIDTH3, "I", $49
;	fwcharmap TX_FULLWIDTH3, "J", $4a
;	fwcharmap TX_FULLWIDTH3, "K", $4b
;	fwcharmap TX_FULLWIDTH3, "L", $4c
;	fwcharmap TX_FULLWIDTH3, "M", $4d
;	fwcharmap TX_FULLWIDTH3, "N", $4e
;	fwcharmap TX_FULLWIDTH3, "O", $4f
;	fwcharmap TX_FULLWIDTH3, "P", $50
;	fwcharmap TX_FULLWIDTH3, "Q", $51
;	fwcharmap TX_FULLWIDTH3, "R", $52
;	fwcharmap TX_FULLWIDTH3, "S", $53
;	fwcharmap TX_FULLWIDTH3, "T", $54
;	fwcharmap TX_FULLWIDTH3, "U", $55
;	fwcharmap TX_FULLWIDTH3, "V", $56
;	fwcharmap TX_FULLWIDTH3, "W", $57
;	fwcharmap TX_FULLWIDTH3, "X", $58
;	fwcharmap TX_FULLWIDTH3, "Y", $59
;	fwcharmap TX_FULLWIDTH3, "Z", $5a
;	fwcharmap TX_FULLWIDTH3, "[", $5b ; opening bracket
;	fwcharmap TX_FULLWIDTH3, "\\", $5c ; backslash
;	fwcharmap TX_FULLWIDTH3, "]", $5d ; closing bracket
;	fwcharmap TX_FULLWIDTH3, "^", $5e ; caret
;	fwcharmap TX_FULLWIDTH3, "_", $5f ; underscore
;	fwcharmap TX_FULLWIDTH3, "`", $60 ; backtick
;	fwcharmap TX_FULLWIDTH3, "a", $61
;	fwcharmap TX_FULLWIDTH3, "b", $62
;	fwcharmap TX_FULLWIDTH3, "c", $63
;	fwcharmap TX_FULLWIDTH3, "d", $64
;	fwcharmap TX_FULLWIDTH3, "e", $65
;	fwcharmap TX_FULLWIDTH3, "f", $66
;	fwcharmap TX_FULLWIDTH3, "g", $67
;	fwcharmap TX_FULLWIDTH3, "h", $68
;	fwcharmap TX_FULLWIDTH3, "i", $69
;	fwcharmap TX_FULLWIDTH3, "j", $6a
;	fwcharmap TX_FULLWIDTH3, "k", $6b
;	fwcharmap TX_FULLWIDTH3, "l", $6c
;	fwcharmap TX_FULLWIDTH3, "m", $6d
;	fwcharmap TX_FULLWIDTH3, "n", $6e
;	fwcharmap TX_FULLWIDTH3, "o", $6f
;	fwcharmap TX_FULLWIDTH3, "p", $70
;	fwcharmap TX_FULLWIDTH3, "q", $71
;	fwcharmap TX_FULLWIDTH3, "r", $72
;	fwcharmap TX_FULLWIDTH3, "s", $73
;	fwcharmap TX_FULLWIDTH3, "t", $74
;	fwcharmap TX_FULLWIDTH3, "u", $75
;	fwcharmap TX_FULLWIDTH3, "v", $76
;	fwcharmap TX_FULLWIDTH3, "w", $77
;	fwcharmap TX_FULLWIDTH3, "x", $78
;	fwcharmap TX_FULLWIDTH3, "y", $79
;	fwcharmap TX_FULLWIDTH3, "z", $7a
;	fwcharmap TX_FULLWIDTH3, "\{", $7b ; opening brace
;	fwcharmap TX_FULLWIDTH3, "|", $7c ; vertical bar
;	fwcharmap TX_FULLWIDTH3, "}", $7d ; closing brace
;	fwcharmap TX_FULLWIDTH3, "~", $7e ; equivalency sign/tilde
; $7f-$bf ARE MISCELLANEOUS SYMBOLS
	fwcharmap TX_FULLWIDTH3, "■", $7f ; black square (8x8 pixels)
;	fwcharmap TX_FULLWIDTH3, "", $80
;	fwcharmap TX_FULLWIDTH3, "", $81
;	fwcharmap TX_FULLWIDTH3, "", $82
;	fwcharmap TX_FULLWIDTH3, "", $83
	fwcharmap TX_FULLWIDTH3, "—", $84 ; em dash (8 pixels long)
	fwcharmap TX_FULLWIDTH3, "※", $85 ; reference mark
	fwcharmap TX_FULLWIDTH3, "○", $86 ; white circle (7x7 pixels)
;	fwcharmap TX_FULLWIDTH3, "", $87
	fwcharmap TX_FULLWIDTH3, "ḋ", $88 ; 'd
	fwcharmap TX_FULLWIDTH3, "ś", $89 ; 's
	fwcharmap TX_FULLWIDTH3, "ṫ", $8a ; 't
	fwcharmap TX_FULLWIDTH3, "ṛ", $8b ; r.
	fwcharmap TX_FULLWIDTH3, "℃", $8c ; °C (degrees Celcius)
;	fwcharmap TX_FULLWIDTH3, "", $8d
;	fwcharmap TX_FULLWIDTH3, "", $8e
;	fwcharmap TX_FULLWIDTH3, "", $8f
	fwcharmap TX_FULLWIDTH3, "●", $90 ; common rarity symbol
	fwcharmap TX_FULLWIDTH3, "◆", $91 ; uncommon rarity symbol
	fwcharmap TX_FULLWIDTH3, "★", $92 ; rare rarity symbol
	fwcharmap TX_FULLWIDTH3, "☆", $93 ; promo rarity symbol
	fwcharmap TX_FULLWIDTH3, "♪", $94 ; musical note
	fwcharmap TX_FULLWIDTH3, "♀", $95 ; female symbol
	fwcharmap TX_FULLWIDTH3, "♂", $96 ; male symbol
	fwcharmap TX_FULLWIDTH3, "₽", $97 ; pokédollar sign
	fwcharmap TX_FULLWIDTH3, "═", $98 ; centered horizontal thick line (8 pixels long, 2 pixels wide)
	fwcharmap TX_FULLWIDTH3, "║", $99 ; left-aligned vertical thick line (8 pixels long, 2 pixels wide)
	fwcharmap TX_FULLWIDTH3, "╚", $9a ; merged lines ($98/$99)
	fwcharmap TX_FULLWIDTH3, "╔", $9b ; merged lines ($98/$99)
	charmap "[HP]", TX_FULLWIDTH3, $9c, TX_FULLWIDTH3, $9d ; HP symbol
	charmap "[E]",  TX_FULLWIDTH3, $9e, TX_FULLWIDTH3, $9f ; E (Energy) symbol
;	fwcharmap TX_FULLWIDTH3, "", $a0
;	fwcharmap TX_FULLWIDTH3, "", $a1
;	fwcharmap TX_FULLWIDTH3, "", $a2
;	fwcharmap TX_FULLWIDTH3, "", $a3
;	fwcharmap TX_FULLWIDTH3, "", $a4
;	fwcharmap TX_FULLWIDTH3, "", $a5
;	fwcharmap TX_FULLWIDTH3, "", $a6
;	fwcharmap TX_FULLWIDTH3, "", $a7
;	fwcharmap TX_FULLWIDTH3, "", $a8
;	fwcharmap TX_FULLWIDTH3, "", $a9
;	fwcharmap TX_FULLWIDTH3, "", $aa
;	fwcharmap TX_FULLWIDTH3, "", $ab
;	fwcharmap TX_FULLWIDTH3, "", $ac
;	fwcharmap TX_FULLWIDTH3, "", $ad
;	fwcharmap TX_FULLWIDTH3, "", $ae
;	fwcharmap TX_FULLWIDTH3, "", $af
;	fwcharmap TX_FULLWIDTH3, "", $b0
;	fwcharmap TX_FULLWIDTH3, "", $b1
;	fwcharmap TX_FULLWIDTH3, "", $b2
;	fwcharmap TX_FULLWIDTH3, "", $b3
;	fwcharmap TX_FULLWIDTH3, "", $b4
;	fwcharmap TX_FULLWIDTH3, "", $b5
;	fwcharmap TX_FULLWIDTH3, "", $b6
;	fwcharmap TX_FULLWIDTH3, "", $b7
	fwcharmap TX_FULLWIDTH3, "⅓", $b8 ; START button tile 1
	fwcharmap TX_FULLWIDTH3, "⅔", $b9 ; START button tile 2
	fwcharmap TX_FULLWIDTH3, "⅜", $ba ; START button tile 3
	fwcharmap TX_FULLWIDTH3, "【", $bb ; open square bracket
	fwcharmap TX_FULLWIDTH3, "】", $bc ; close square bracket
	fwcharmap TX_FULLWIDTH3, "゛", $bd ; dakuten/ten-ten (Japanese)
	fwcharmap TX_FULLWIDTH3, "゜", $be ; handakuten/maru (Japanese)
	fwcharmap TX_FULLWIDTH3, "¿", $bf ; inverted question mark
; $c0-$fe ARE MOSTLY ASCII CHARACTERS (THE ACCENTS)
	fwcharmap TX_FULLWIDTH3, "À", $c0 ; A with grave accent
	fwcharmap TX_FULLWIDTH3, "Á", $c1 ; A with acute accent
	fwcharmap TX_FULLWIDTH3, "Â", $c2 ; A with circumflex
	fwcharmap TX_FULLWIDTH3, "Ã", $c3 ; A with tilde
	fwcharmap TX_FULLWIDTH3, "Ä", $c4 ; A with diaeresis/umlaut
	fwcharmap TX_FULLWIDTH3, "Å", $c5 ; A with overring
	fwcharmap TX_FULLWIDTH3, "Æ", $c6 ; AE
	fwcharmap TX_FULLWIDTH3, "Ç", $c7 ; C with cedilla accent
	fwcharmap TX_FULLWIDTH3, "È", $c8 ; E with grave accent
	fwcharmap TX_FULLWIDTH3, "É", $c9 ; E with acute accent
	fwcharmap TX_FULLWIDTH3, "Ê", $ca ; E with circumflex 
	fwcharmap TX_FULLWIDTH3, "Ë", $cb ; E with diaeresis/umlaut
	fwcharmap TX_FULLWIDTH3, "Ì", $cc ; I with grave accent
	fwcharmap TX_FULLWIDTH3, "Í", $cd ; I with acute accent
	fwcharmap TX_FULLWIDTH3, "Î", $ce ; I with circumflex
	fwcharmap TX_FULLWIDTH3, "Ï", $cf ; I with diaeresis/umlaut
;	fwcharmap TX_FULLWIDTH3, "", $d0
	fwcharmap TX_FULLWIDTH3, "Ñ", $d1 ; N with tilde
	fwcharmap TX_FULLWIDTH3, "Ò", $d2 ; O with grave accent
	fwcharmap TX_FULLWIDTH3, "Ó", $d3 ; O with acute accent
	fwcharmap TX_FULLWIDTH3, "Ô", $d4 ; O with circumflex
	fwcharmap TX_FULLWIDTH3, "Õ", $d5 ; O with tilde
	fwcharmap TX_FULLWIDTH3, "Ö", $d6 ; O with diaeresis/umlaut
	fwcharmap TX_FULLWIDTH3, "Ø", $d7 ; O with slash
	fwcharmap TX_FULLWIDTH3, "Œ", $d8 ; OE
	fwcharmap TX_FULLWIDTH3, "Ù", $d9 ; U with grave accent
	fwcharmap TX_FULLWIDTH3, "Ú", $da ; U with acute accent
	fwcharmap TX_FULLWIDTH3, "Û", $db ; U with circumflex
	fwcharmap TX_FULLWIDTH3, "Ü", $dc ; U with diaeresis/umlaut
	fwcharmap TX_FULLWIDTH3, "Ý", $dd ; Y with acute accent
	fwcharmap TX_FULLWIDTH3, "Ÿ", $de ; Y with diaeresis/umlaut
	fwcharmap TX_FULLWIDTH3, "ß", $df ; sharp s
	fwcharmap TX_FULLWIDTH3, "à", $e0 ; a with grave accent
	fwcharmap TX_FULLWIDTH3, "á", $e1 ; a with acute accent
	fwcharmap TX_FULLWIDTH3, "â", $e2 ; a with circumflex
	fwcharmap TX_FULLWIDTH3, "ã", $e3 ; a with tilde
	fwcharmap TX_FULLWIDTH3, "ä", $e4 ; a with diaeresis/umlaut
	fwcharmap TX_FULLWIDTH3, "å", $e5 ; a with overring
	fwcharmap TX_FULLWIDTH3, "æ", $e6 ; ae
	fwcharmap TX_FULLWIDTH3, "ç", $e7 ; c with cedilla
	fwcharmap TX_FULLWIDTH3, "è", $e8 ; e with grave accent
	fwcharmap TX_FULLWIDTH3, "é", $e9 ; e with acute accent
	fwcharmap TX_FULLWIDTH3, "ê", $ea ; e with circumflex
	fwcharmap TX_FULLWIDTH3, "ë", $eb ; e with diaeresis/umlaut
	fwcharmap TX_FULLWIDTH3, "ì", $ec ; i with grave accent
	fwcharmap TX_FULLWIDTH3, "í", $ed ; i with acute accent
	fwcharmap TX_FULLWIDTH3, "î", $ee ; i with circumflex
	fwcharmap TX_FULLWIDTH3, "ï", $ef ; i with diaeresis/umlaut
;	fwcharmap TX_FULLWIDTH3, "", $f0
	fwcharmap TX_FULLWIDTH3, "ñ", $f1 ; n with tilde
	fwcharmap TX_FULLWIDTH3, "ò", $f2 ; o with grave accent
	fwcharmap TX_FULLWIDTH3, "ó", $f3 ; o with acute accent
	fwcharmap TX_FULLWIDTH3, "ô", $f4 ; o with circumflex
	fwcharmap TX_FULLWIDTH3, "õ", $f5 ; o with tilde
	fwcharmap TX_FULLWIDTH3, "ö", $f6 ; o with diaeresis/umlautt
	fwcharmap TX_FULLWIDTH3, "ø", $f7 ; o with slash
	fwcharmap TX_FULLWIDTH3, "œ", $f8 ; oe
	fwcharmap TX_FULLWIDTH3, "ù", $f9 ; u with grave accent
	fwcharmap TX_FULLWIDTH3, "ú", $fa ; u with acute accent
	fwcharmap TX_FULLWIDTH3, "û", $fb ; u with circumflex
	fwcharmap TX_FULLWIDTH3, "ü", $fc ; u with diaeresis/umlaut
	fwcharmap TX_FULLWIDTH3, "ý", $fd ; y with acute accent
	fwcharmap TX_FULLWIDTH3, "ÿ", $fe ; y with diaeresis/umlaut


MACRO txsymbol
	REDEF symbol EQUS \1
	charmap "<{symbol}>", TX_SYMBOL, const_value
	PUSHC main
	charmap "<{symbol}>", TX_SYMBOL, const_value
	POPC
	const SYM_{symbol}
ENDM

; TX_SYMBOL
	const_def
	txsymbol "SPACE"          ; $00
	txsymbol "FIRE"           ; $01
	txsymbol "GRASS"          ; $02
	txsymbol "LIGHTNING"      ; $03
	txsymbol "WATER"          ; $04
	txsymbol "FIGHTING"       ; $05
	txsymbol "PSYCHIC"        ; $06
	txsymbol "COLORLESS"      ; $07
	txsymbol "POISONED"       ; $08
	txsymbol "ASLEEP"         ; $09
	txsymbol "CONFUSED"       ; $0a
	txsymbol "PARALYZED"      ; $0b
	txsymbol "CURSOR_U"       ; $0c
	txsymbol "CURSOR_D"       ; $0d
	txsymbol "CURSOR_L"       ; $0e
	txsymbol "CURSOR_R"       ; $0f
	txsymbol "UNUSED_10"      ; $10
	txsymbol "UNUSED_11"      ; $11
	txsymbol "UNUSED_12"      ; $12
	txsymbol "DAMAGE_COUNTER" ; $13
	txsymbol "PLUSPOWER"      ; $14
	txsymbol "DEFENDER"       ; $15
	txsymbol "BOX_HEADER_L"   ; $16
	txsymbol "BOX_HEADER_R"   ; $17
	txsymbol "BOX_TOP_L"      ; $18
	txsymbol "BOX_TOP_R"      ; $19
	txsymbol "BOX_BTM_L"      ; $1a
	txsymbol "BOX_BTM_R"      ; $1b
	txsymbol "BOX_TOP"        ; $1c
	txsymbol "BOX_BOTTOM"     ; $1d
	txsymbol "BOX_LEFT"       ; $1e
	txsymbol "BOX_RIGHT"      ; $1f
	txsymbol "0"              ; $20
	txsymbol "1"              ; $21
	txsymbol "2"              ; $22
	txsymbol "3"              ; $23
	txsymbol "4"              ; $24
	txsymbol "5"              ; $25
	txsymbol "6"              ; $26
	txsymbol "7"              ; $27
	txsymbol "8"              ; $28
	txsymbol "9"              ; $29
	txsymbol "DOT"            ; $2a
	txsymbol "PLUS"           ; $2b
	txsymbol "MINUS"          ; $2c
	txsymbol "CROSS"          ; $2d
	txsymbol "SLASH"          ; $2e
	txsymbol "POKEMON"        ; $2f
	txsymbol "PRIZE"          ; $30

SETCHARMAP main
