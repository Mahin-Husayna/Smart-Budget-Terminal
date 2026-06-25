print_line MACRO string
    LEA DX, string
    MOV AH, 09h
    INT 21h
ENDM

.model small
.stack 100h

.data
    ;for register and login (Mahin)
    username DB 20 DUP('$')
    password DB 20 DUP('$')
    in_user  DB 20 DUP('$')
    in_pass  DB 20 DUP('$')
    reg_msg DB 10,13,'--Register First--$'
    login_msg DB 10,13,'--Login--$'
    ask_user  DB 10,13,'Username: $'
    ask_pass DB 10,13,'Password: $'
    reg_ok   DB 10,13,'Registration successful! Press any key to continue...$'
    login_ok DB 10,13,'Login successful! Press any key to continue...$'
    login_fail DB 10,13,'Wrong login.Try again.$'
    
    category_count DW 3   ;For category feature: (Mahin)
    categories DW 5 DUP(0)
    cat4 DB 12 DUP(' '),'$'
    cat5 DB 12 DUP(' '),'$'
    cat_added_msg DB 10,13,'Category added successfully! Press any key...$'
    cat_full_msg DB 10,13,'Maximum 5 categories allowed! Press any key...$'   
    
    cat_header DB 10,13,10,13,'--- Expenses by Category ---',10,13,'$'
    cat1_msg DB '1. Food: $$'
    cat2_msg DB 10,13,'2. Rent: $$'
    cat3_msg DB 10,13,'3. Fun : $$'
    cat4_msg DB 10,13,'4. $'
    cat5_msg DB 10,13,'5. $'
    colon_money DB ': $$'
    prompt_cat DB 10,13,'Select Category Number: $'
    prompt_newcat DB 10,13,'Enter New Category Name: $'   
    
    warn_msg        DB 10,13,10,13,'  !!! WARNING: LOW BUDGET !!!$'
    
    
    
    
    
    ;CORE 
    current_balance DW 0
    total_income    DW 0
    total_expenses  DW 0
    threshold       DW 300  
    
  
    empty_blocks DW 0

    ; ---------------- HISTORY ----------------
    hist_type       DW 5 DUP(0)      ; 1-5 category, 99 income
    hist_amt        DW 5 DUP(0)

    ; ---------------- UNDO STACK ----------------
    undo_type       DW 10 DUP(0)
    undo_amt        DW 10 DUP(0)
    undo_count      DW 0

    ; ---------------- UI ----------------
    title_msg       DB '====================================',10,13
                    DB '      SMART BUDGET TERMINAL v3      ',10,13
                    DB '====================================',10,13,'$'

    balance_msg     DB 'Current Balance: $$'
    health_msg      DB 10,13,'Budget Health:   $'

    

    hist_header     DB 10,13,10,13,'--- Recent Log ---$'
    log_inc_msg     DB 10,13,'  + Income: $$'
    log_exp_msg     DB 10,13,'  - Expense on $'
    log_undo_msg    DB 10,13,'  * Last transaction undone.$'

    

    menu_msg        DB 10,13,10,13
                    DB '+----------------------------------+',10,13
                    DB '| 1. Add Income                    |',10,13
                    DB '| 2. Add Expense                   |',10,13
                    DB '| 3. Undo Last Transaction         |',10,13
                    DB '| 4. Add New Category              |',10,13
                    DB '| 0. Exit                          |',10,13
                    DB '+----------------------------------+',10,13
                    DB 'Select: $'

    prompt_amt      DB 10,13,'Enter Amount: $$'

    invalid_msg     DB 10,13,'Invalid input! Press any key...$'
    insuff_msg      DB 10,13,'Insufficient balance! Press any key...$'
    no_undo_msg     DB 10,13,'Nothing to undo! Press any key...$'
    bye_msg         DB 10,13,'Goodbye!$'

.code

MAIN PROC
    MOV AX, @data
    MOV DS, AX

    CALL REGISTER_SCREEN
    CALL LOGIN_SCREEN

main_loop:
    CALL DRAW_DASHBOARD

    MOV AH, 01h
    INT 21h

    CMP AL, '1'
    JE do_income
    CMP AL, '2'
    JE do_expense
    CMP AL, '3'
    JE do_undo
    CMP AL, '4'
    JE do_add_Category
    CMP AL, '0'
    JE exit_program

    CALL SHOW_INVALID
    JMP main_loop

do_income:
    CALL ADD_INCOME
    JMP main_loop

do_expense:
    CALL ADD_EXPENSE
    JMP main_loop

do_undo:
    CALL UNDO_LAST
    JMP main_loop

do_add_Category:
    CALL add_Category
    JMP main_loop

exit_program:
    print_line bye_msg
    MOV AH, 4Ch
    INT 21h
MAIN ENDP
     
     
;REGISTER AND LOGIN SYSTEM (Mahin)


;Register screen show korbe
REGISTER_SCREEN PROC
    CALL CLEAR_SCREEN
    print_line title_msg
    print_line reg_msg

    print_line ask_user
    LEA DI,username
    CALL READ_STRING

    print_line ask_pass
    LEA DI,password
    CALL READ_STRING

    print_line reg_ok
    CALL WAIT_KEY
    RET
REGISTER_SCREEN ENDP


;Login Screen show korbe
LOGIN_SCREEN PROC
login_try:
    CALL CLEAR_SCREEN
    print_line title_msg
    print_line login_msg

    print_line ask_user
    LEA DI,in_user
    CALL READ_STRING

    print_line ask_pass
    LEA DI,in_pass
    CALL READ_STRING

    LEA SI,username
    LEA DI,in_user
    CALL STR_COMPARE
    CMP AX, 1
    JNE bad_login

    LEA SI,password
    LEA DI,in_pass
    CALL STR_COMPARE
    CMP AX, 1
    JNE bad_login

    print_line login_ok
    CALL WAIT_KEY
    RET

bad_login:
    print_line login_fail
    CALL WAIT_KEY
    JMP login_try
LOGIN_SCREEN ENDP




; ADD INCOME(Labiba)
ADD_INCOME PROC
    print_line prompt_amt
    CALL READ_NUM

    CMP AX, 0
    JE bad_income

    ADD current_balance, AX
    ADD total_income, AX

    MOV SI, 99
    MOV DI, AX
    CALL UPDATE_HISTORY

    MOV SI, 99
    MOV DI, AX
    CALL PUSH_UNDO

    RET

bad_income:
    CALL SHOW_INVALID
    RET
ADD_INCOME ENDP


; ADD EXPENSE(Labiba)
ADD_EXPENSE PROC
    print_line prompt_amt
    CALL READ_NUM

    CMP AX, 0
    JE bad_expense

    CMP AX, current_balance
    JG not_enough

    MOV DI, AX

    CALL PRINT_CATEGORIES

    print_line prompt_cat
    MOV AH, 01h
    INT 21h

    CMP AL, '1'
    JL bad_expense

    CMP AL, '5'
    JG bad_expense

    SUB AL, '0'
    MOV AH, 0

    CMP AX, category_count
    JG bad_expense

    MOV SI, AX              ; category type 1-5

    DEC AX
    SHL AX, 1
    MOV BX, AX              ; category offset

    MOV AX, DI

    SUB current_balance, AX
    ADD total_expenses, AX
    ADD categories[BX], AX

    MOV DI, AX
    CALL UPDATE_HISTORY

    MOV DI, AX
    CALL PUSH_UNDO

    RET

not_enough:
    print_line insuff_msg
    CALL WAIT_KEY
    RET

bad_expense:
    CALL SHOW_INVALID
    RET
ADD_EXPENSE ENDP

;Adding new category part (Mahin)
add_Category PROC
    MOV AX, category_count
    CMP AX, 5
    JGE category_full

    CMP AX, 3
    JE add_fourth

    CMP AX, 4
    JE add_fifth

    RET

add_fourth:
    print_line prompt_newcat
    LEA DI, cat4
    CALL CLEAR_NAME
    LEA DI, cat4
    CALL READ_STRING

    INC category_count
    print_line cat_added_msg
    CALL WAIT_KEY
    RET

add_fifth:
    print_line prompt_newcat
    LEA DI, cat5
    CALL CLEAR_NAME
    LEA DI, cat5
    CALL READ_STRING

    INC category_count
    print_line cat_added_msg
    CALL WAIT_KEY
    RET

category_full:
    print_line cat_full_msg
    CALL WAIT_KEY
    RET
add_Category ENDP

;Categories print korbe


PRINT_CATEGORIES PROC
    print_line cat_header

    print_line cat1_msg
    MOV AX,categories[0]
    CALL PRINT_NUM

    MOV AX,category_count
    CMP AX,2
    JL pc_done

    print_line cat2_msg
    MOV AX,categories[2]
    CALL PRINT_NUM

    MOV AX,category_count
    CMP AX,3
    JL pc_done

    print_line cat3_msg
    MOV AX,categories[4]
    CALL PRINT_NUM

    MOV AX,category_count
    CMP AX,4
    JL pc_done

    print_line cat4_msg
    print_line cat4
    print_line colon_money
    MOV AX, categories[6]
    CALL PRINT_NUM

    MOV AX,category_count
    CMP AX,5
    JL pc_done

    print_line cat5_msg
    print_line cat5
    print_line colon_money
    MOV AX,categories[8]
    CALL PRINT_NUM

pc_done:
    RET
PRINT_CATEGORIES ENDP     




;REVERT TRANSACTION

; PUSH UNDO
; SI = type, DI = amount
PUSH_UNDO PROC
    PUSH AX
    PUSH BX
    PUSH CX

    MOV AX, undo_count
    CMP AX, 10
    JL undo_space

    MOV CX, 9
    MOV BX, 0

shift_undo:
    MOV AX, undo_type[BX+2]
    MOV undo_type[BX], AX

    MOV AX, undo_amt[BX+2]
    MOV undo_amt[BX], AX

    ADD BX, 2
    LOOP shift_undo

    MOV undo_count, 9

undo_space:
    MOV BX, undo_count
    SHL BX, 1

    MOV undo_type[BX], SI
    MOV undo_amt[BX], DI

    INC undo_count

    POP CX
    POP BX
    POP AX
    RET
PUSH_UNDO ENDP


;undo tansactions,calcultaions
UNDO_LAST PROC
    CMP undo_count, 0
    JE nothing_undo

    DEC undo_count

    MOV BX, undo_count
    SHL BX, 1

    MOV SI, undo_type[BX]
    MOV AX, undo_amt[BX]

    CMP SI, 99
    JE undo_income

undo_expense:
    ADD current_balance, AX
    SUB total_expenses, AX

    MOV DX, SI
    DEC DX
    SHL DX, 1
    MOV BX, DX

    SUB categories[BX], AX

    JMP undo_done

undo_income:
    SUB current_balance, AX
    SUB total_income, AX

undo_done:
    CALL REMOVE_LATEST_HISTORY
    print_line log_undo_msg
    CALL WAIT_KEY
    RET

nothing_undo:
    print_line no_undo_msg
    CALL WAIT_KEY
    RET
UNDO_LAST ENDP


;old history niche jabe and store new action top e
; SI = type, DI = amount(history update) 
UPDATE_HISTORY PROC
    PUSH AX
    PUSH BX
    PUSH CX

    MOV CX, 4
    MOV BX, 6

shift_hist:
    MOV AX, hist_amt[BX]
    MOV hist_amt[BX+2], AX

    MOV AX, hist_type[BX]
    MOV hist_type[BX+2], AX

    SUB BX, 2
    LOOP shift_hist

    MOV hist_amt[0], DI
    MOV hist_type[0], SI

    POP CX
    POP BX
    POP AX
    RET
UPDATE_HISTORY ENDP


;lastest history top theke remove korbe undo korar por(remove history)
REMOVE_LATEST_HISTORY PROC
    PUSH AX
    PUSH BX
    PUSH CX

    MOV CX, 4
    MOV BX, 0

shift_left:
    MOV AX, hist_amt[BX+2]
    MOV hist_amt[BX], AX

    MOV AX, hist_type[BX+2]
    MOV hist_type[BX], AX

    ADD BX, 2
    LOOP shift_left

    MOV hist_amt[8], 0
    MOV hist_type[8], 0

    POP CX
    POP BX
    POP AX
    RET
REMOVE_LATEST_HISTORY ENDP


;DASHBOARD Draw korbe

DRAW_DASHBOARD PROC
    CALL CLEAR_SCREEN

    MOV AX, current_balance
    CMP AX, threshold
    JGE normal_screen
    CALL RED_TOP_BAR

normal_screen:
    print_line title_msg

    print_line balance_msg
    MOV AX, current_balance
    CALL PRINT_NUM

    CALL DRAW_HEALTH_BAR

    CALL PRINT_CATEGORIES
    CALL DRAW_HISTORY
    
    
    
    ;Low Budget warning (Mahin)
    MOV AX,current_balance
    CMP AX,threshold
    JGE no_warning
    print_line warn_msg

no_warning:
    print_line menu_msg
    RET
DRAW_DASHBOARD ENDP


;HISTORY Draw korbe

DRAW_HISTORY PROC
    print_line hist_header

    MOV CX, 5
    MOV BX, 0

hist_loop:
    PUSH CX
    PUSH BX

    MOV AX, hist_type[BX]

    CMP AX, 0
    JE hist_skip

    CMP AX, 99
    JE h_income

    print_line log_exp_msg
    CALL PRINT_CATEGORY_NAME
    print_line colon_money

    POP BX
    PUSH BX

    MOV AX, hist_amt[BX]
    CALL PRINT_NUM
    JMP hist_skip

h_income:
    print_line log_inc_msg

    POP BX
    PUSH BX

    MOV AX, hist_amt[BX]
    CALL PRINT_NUM

hist_skip:
    POP BX
    POP CX

    ADD BX, 2
    LOOP hist_loop

    RET
DRAW_HISTORY ENDP

; Catagory name print korbe
; AX = category number 1-5 store korbe

PRINT_CATEGORY_NAME PROC
    CMP AX, 1
    JE pcat_food
    CMP AX, 2
    JE pcat_rent
    CMP AX, 3
    JE pcat_fun
    CMP AX, 4
    JE pcat_four
    CMP AX, 5
    JE pcat_five
    RET

pcat_food:
    MOV AH, 02h
    MOV DL,'F'
    INT 21h
    MOV DL,'o'
    INT 21h
    MOV DL,'o'
    INT 21h
    MOV DL,'d'
    INT 21h
    RET

pcat_rent:
    MOV AH, 02h
    MOV DL,'R'
    INT 21h
    MOV DL,'e'
    INT 21h
    MOV DL,'n'
    INT 21h
    MOV DL,'t'
    INT 21h
    RET

pcat_fun:
    MOV AH,02h
    MOV DL,'F'
    INT 21h
    MOV DL,'u'
    INT 21h
    MOV DL,'n'
    INT 21h
    RET

pcat_four:
    print_line cat4
    RET

pcat_five:
    print_line cat5
    RET
PRINT_CATEGORY_NAME ENDP


;budget level dekhabe in the form of a health bar. low budget == red bar
DRAW_HEALTH_BAR PROC
    print_line health_msg

    MOV AX, total_income
    CMP AX, 0
    JE no_income_bar

    MOV AX, total_expenses
    MOV BX, 10
    MUL BX
    MOV BX, total_income
    DIV BX

    CMP AX, 10
    JLE ratio_ok
    MOV AX, 10

ratio_ok:
    MOV CX, AX

    MOV BX, 10
    SUB BX, AX
    MOV empty_blocks, BX

    MOV AX, current_balance
    CMP AX, threshold
    JL red_bar

    MOV AX, total_expenses
    CMP AX, total_income
    JL green_bar

yellow_bar:
    MOV BL, 0Eh
    JMP draw_used

green_bar:
    MOV BL, 0Ah
    JMP draw_used

red_bar:
    MOV BL, 0Ch

draw_used:
    MOV DL, '['
    MOV AH, 02h
    INT 21h

    CMP CX, 0
    JE draw_empty

used_loop:
    MOV AL, 219
    CALL PRINT_COLOR_CHAR
    LOOP used_loop

draw_empty:
    MOV CX, empty_blocks
    CMP CX, 0
    JE close_bar

empty_loop:
    MOV DL, '.'
    MOV AH, 02h
    INT 21h
    LOOP empty_loop

close_bar:
    MOV DL, ']'
    MOV AH, 02h
    INT 21h
    RET

no_income_bar:
    MOV DL, '['
    MOV AH, 02h
    INT 21h

    MOV CX, 10
zero_bar_loop:
    MOV DL, '.'
    MOV AH, 02h
    INT 21h
    LOOP zero_bar_loop

    MOV DL, ']'
    MOV AH, 02h
    INT 21h
    RET
DRAW_HEALTH_BAR ENDP


; PRINT COLORED CHARACTER
; AL = character, BL = color
PRINT_COLOR_CHAR PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH, 09h
    MOV BH, 0
    MOV CX, 1
    INT 10h

    MOV AH, 03h
    MOV BH, 0
    INT 10h

    INC DL
    MOV AH, 02h
    MOV BH, 0
    INT 10h

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_COLOR_CHAR ENDP


; RED WARNING TOP BAR
RED_TOP_BAR PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH, 09h
    MOV AL, '!'
    MOV BH, 0
    MOV BL, 8Ch
    MOV CX, 80
    INT 10h

    MOV AH, 02h
    MOV BH, 0
    MOV DH, 1
    MOV DL, 0
    INT 10h

    POP DX
    POP CX
    POP BX
    POP AX
    RET
RED_TOP_BAR ENDP 

; READ STRING
READ_STRING PROC
    PUSH AX
    PUSH CX
    PUSH DI

    MOV CX, 19

read_s_loop:
    MOV AH, 01h
    INT 21h

    CMP AL, 0Dh
    JE end_read_s

    CMP CX, 0
    JE read_s_loop

    MOV [DI], AL
    INC DI
    DEC CX

    JMP read_s_loop

end_read_s:
    MOV BYTE PTR [DI], '$'

    POP DI
    POP CX
    POP AX
    RET
READ_STRING ENDP

; READ POSITIVE NUMBER 
READ_NUM PROC
    PUSH BX
    PUSH CX
    PUSH DX

    MOV CX, 0

read_loop:
    MOV AH, 01h
    INT 21h

    CMP AL, 0Dh
    JE end_read

    CMP AL, '0'
    JL read_loop
    CMP AL, '9'
    JG read_loop

    SUB AL, '0'
    MOV AH, 0
    PUSH AX

    MOV AX, CX
    MOV BX, 10
    MUL BX

    POP BX
    ADD AX, BX
    MOV CX, AX

    JMP read_loop

end_read:
    MOV AX, CX

    POP DX
    POP CX
    POP BX
    RET
READ_NUM ENDP


;STRINGS comapare korbe

STR_COMPARE PROC
compare_loop:
    MOV AL, [SI]
    MOV BL, [DI]

    CMP AL, '$'
    JE check_end

    CMP AL, BL
    JNE not_same

    INC SI
    INC DI
    JMP compare_loop

check_end:
    CMP BL, '$'
    JNE not_same
    MOV AX, 1
    RET

not_same:
    MOV AX, 0
    RET
STR_COMPARE ENDP


; CLEAR CATEGORY NAME

CLEAR_NAME PROC
    PUSH AX
    PUSH CX
    PUSH DI

    MOV CX, 12
clear_name_loop:
    MOV BYTE PTR [DI],' '
    INC DI
    LOOP clear_name_loop

    MOV BYTE PTR [DI],'$'

    POP DI
    POP CX
    POP AX
    RET
CLEAR_NAME ENDP 



; PRINT NUMBERs
PRINT_NUM PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX, 0
    JNE print_nonzero

    MOV DL, '0'
    MOV AH, 02h
    INT 21h
    JMP print_done

print_nonzero:
    MOV CX, 0
    MOV BX, 10

digit_loop:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE digit_loop

print_loop:
    POP DX
    ADD DL, 30h
    MOV AH, 02h
    INT 21h
    LOOP print_loop

print_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUM ENDP


; HELPERS
SHOW_INVALID PROC
    print_line invalid_msg
    CALL WAIT_KEY
    RET
SHOW_INVALID ENDP

WAIT_KEY PROC
    MOV AH, 07h
    INT 21h
    RET
WAIT_KEY ENDP

CLEAR_SCREEN PROC
    MOV AX, 0600h
    MOV BH, 07h
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h

    MOV AH, 02h
    MOV BH, 0
    MOV DX, 0000h
    INT 10h
    RET
CLEAR_SCREEN ENDP

END MAIN