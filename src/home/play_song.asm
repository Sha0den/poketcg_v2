ScriptPlaySong::
	call PlaySong
	ret

WaitForSongToFinish::
	call DoFrameIfLCDEnabled
	call AssertSongFinished
	or a
	jr nz, WaitForSongToFinish
	ret

;
;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
;Func_3c87::
;	push af
;	call PauseSong
;	pop af
;	call PlaySong
;	call WaitForSongToFinish
;	call ResumeSong
;	ret
