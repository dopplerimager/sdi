;\\ Code formatted by DocGen


;\D\<No Doc>
PRO ShowProgress::Destroy

;\D\<No Doc>
PRO ShowProgress::UpDate, percent  ;\A\<No Doc>

;\D\<No Doc>
PRO ShowProgress::Process_Events, event  ;\A\<No Doc>

;\D\<No Doc>
PRO ShowProgress_Event, event  ;\A\<No Doc>

;\D\<No Doc>
PRO ShowProgress::Start

;\D\<No Doc>
PRO ShowProgress_Cleanup, tlb  ;\A\<No Doc>

;\D\<No Doc>
PRO ShowProgress::ReInitialize

;\D\<No Doc>
PRO ShowProgress::Cleanup

;\D\<No Doc>
PRO ShowProgress::GetProperty, Parent=parent, $           ;\A\<No Doc>
                               Delay=delay, $             ;\A\<No Doc>
                               Steps=nsteps, $            ;\A\<No Doc>
                               Message=message, $         ;\A\<No Doc>
                               Title=title, $             ;\A\<No Doc>
                               Color=color, $             ;\A\<No Doc>
                               XSize=xsize, $             ;\A\<No Doc>
                               YSize=ysize, $             ;\A\<No Doc>
                               AutoUpdate=autoupdate      ;\A\<No Doc>

;\D\<No Doc>
PRO ShowProgress::SetProperty, Parent=parent, $           ;\A\<No Doc>
                               Delay=delay, $             ;\A\<No Doc>
                               Steps=nsteps, $            ;\A\<No Doc>
                               Message=message, $         ;\A\<No Doc>
                               Title=title, $             ;\A\<No Doc>
                               Color=color, $             ;\A\<No Doc>
                               XSize=xsize, $             ;\A\<No Doc>
                               YSize=ysize, $             ;\A\<No Doc>
                               AutoUpdate=autoupdate      ;\A\<No Doc>

;\D\<No Doc>
FUNCTION ShowProgress::Init, parent, $                  ;\A\<No Doc>
                             Delay=delay, $             ;\A\<No Doc>
                             Steps=nsteps, $            ;\A\<No Doc>
                             Message=message, $         ;\A\<No Doc>
                             Title=title, $             ;\A\<No Doc>
                             Color=color, $             ;\A\<No Doc>
                             XSize=xsize, $             ;\A\<No Doc>
                             YSize=ysize, $             ;\A\<No Doc>
                             AutoUpdate=autoupdate      ;\A\<No Doc>

;\D\<No Doc>
PRO ShowProgress__Define

;\D\<No Doc>
PRO Example_Event, event  ;\A\<No Doc>

; Respond to program button events.

Widget_Control, event.id, Get_Value=buttonValue, Get_UValue=timer

CASE buttonValue OF

   'Automatic Mode':timer->start

   'Manual Mode': BEGIN ; Updating of Show Progress widget occurs in loop.
      timer->start
      count = 0
      FOR j=0, 1000 DO BEGIN
          if j mod 100 EQ 0 THEN BEGIN
            timer->update, (count * 10.0)
            count = count + 1
          endif
          Wait, 0.001 ; This is where you would do something useful.
      ENDFOR
      timer->destroy
      ENDCASE

   'Quit': Widget_Control, event.top, /Destroy

ENDCASE
END

;\D\<No Doc>
PRO Example_Cleanup, tlb  ;\A\<No Doc>

   ; Cleanup routine when TLB widget dies. Be sure
   ; to destroy Show Progress objects.

Widget_Control, tlb, Get_UValue=info
Obj_Destroy, info[0]
Obj_Destroy, info[1]
END

;\D\<No Doc>
PRO Example
Device, Decomposed=0
TVLCT, 255, 0, 0, 20
tlb = Widget_Base(Column=1, Xoffset=200, Yoffset=200)

   ; Create an AutoUpDate object. Store in UValue of Button.

autoTimer = Obj_New("ShowProgress", tlb, Color=20, Steps=20, Delay=5, /AutoUpdate)
button = Widget_Button(tlb, Value='Automatic Mode', UValue=autoTimer)

   ; Create a Manual Show Progress object. Store in UValue of Button.

progressTimer = Obj_New("ShowProgress", tlb, Color=20)
button = Widget_Button(tlb, Value='Manual Mode', UValue=progressTimer)

quiter = Widget_Button(tlb, Value='Quit', UValue='QUIT')

Widget_Control, tlb, /Realize, Set_UValue=[autoTimer, progressTimer]
XManager, 'example', tlb, /No_Block, Cleanup='example_cleanup'
END
