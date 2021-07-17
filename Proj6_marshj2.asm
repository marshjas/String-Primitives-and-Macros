
TITLE Project 6 - String Primitives and Macros (Proj6_marshj2.asm)

; Author: Jason Marsh
; Last Modified: 5/31/2021
; OSU email address: marshj2@oregonstate.edu
; Course number/section: CS271   CS271 Section 400
; Project Number: 6                 Due Date: 6/6/2021
; Description: String Primitives and Macros. This program will take 10 signed integers as
; input from the user, catching if any invalid input is entered. It will then store those values
; in an array, display them to the user, and then calculate the sum of the integers as well as
; the rounded-down average.

INCLUDE Irvine32.inc

; macros

;--------------------------------------------------------
; Name: mDisplayString
;
; Displays a given string in the console
;
; Preconditions: inputString must be a string
;
; Postconditions: inputString printed to the console
;
; Receives: inputString
;
; Returns: none
;--------------------------------------------------------
mDisplayString	MACRO	inputString
	push		EDX
	mov			EDX, inputString
	call		WriteString
	pop			EDX
ENDM

;--------------------------------------------------------
; Name: mGetString
;
; Displays an input prompt and reads user-input string
;
; Preconditions: inputPrompt must be a string, outputString 
; must be a buffer accomodating the max size of the string
;
; Postconditions: inputPrompt displayed, outputString
; filled with value entered by user
;
; Receives: inputPrompt and outputString
;
; Returns: none
;--------------------------------------------------------
mGetString		MACRO	inputPrompt, outputString
	push		EDX
	push		ECX

	mDisplayString	inputPrompt

	mov			EDX, outputString
	mov			ECX, 13
	call		ReadString

	pop			ECX
	pop			EDX
ENDM

; constants
ARRAYSIZE		=			10

.data
; variables
intro			BYTE		"Name: Jason Marsh",13,10,"Description: Project 6 - String Primitives and Macros.",13,10,"Takes 10 signed integers as input, displays them, and calculates/displays their sum and rounded-down average.",13,10,13,10,0
instructions	BYTE		"Please enter 10 signed decimal integers",13,10,"The number must be small enough to fit inside a 32-bit register",13,10,"We will the display the integers, their sum, and their average value",13,10,13,10,0
prompt			BYTE		"Please enter a signed decimal integer: ",0
buffer			BYTE		21 DUP(0)
inputList		DWORD		13 DUP(0)
outputList		DWORD		13 DUP(0)
outstring		BYTE		13 DUP(0)
error			BYTE		"You did not enter a valid signed integer, or your number was too big",0
space			BYTE		", ",0
displayTitle	BYTE		"Here are the values you entered: ",0
minus			BYTE		"-",0
sumTitle		BYTE		"The sum of these numbers is: ",0
avgTitle		BYTE		"The rounded average: ",0
farewell		BYTE		"Thank you and goodbye!",0


.code
main PROC

	mDisplayString OFFSET intro			; display intro and instructions
	mDisplayString OFFSET instructions

	mov		ECX, ARRAYSIZE				; use ARRAYSIZE constant to determine how many numbers to ask for
	mov		ESI, OFFSET inputList		; use ESI to store input, EDI to store array of ints
	mov		EDI, OFFSET outputList

_getValLoop:							; loop through input 10 times to get 10 values
	push	OFFSET error
	push	OFFSET outputList
	push	OFFSET inputList
	push	OFFSET prompt
	call	readVal
	loop	_getValLoop

	push	OFFSET minus				; display list of ints to user
	push	OFFSET outstring
	push	OFFSET space
	push	OFFSET outputList
	push	OFFSET displayTitle
	call	displayList

	push	OFFSET outstring			; calculate sum and median and display both
	push	OFFSET minus
	push	OFFSET avgTitle
	push	OFFSET sumTitle
	push	OFFSET outputList
	call	sumArray

	call	CrLf
	mDisplayString OFFSET farewell		; say goodbye

	Invoke ExitProcess,0				; exit to operating system
main ENDP

;--------------------------------------------------------
; Name: readVal
;
; Takes a string and stores it in an array
;
; Preconditions: Prompt message must be a string
; must have string value pushed to the stack as
; well as array location marker
;
; Postconditions: Value stored in array
;
; Receives:
;		[EBP + 8]  = Prompt message
;		[EBP + 12] = String value being received
;		[EBP + 16] = array location marker
;		[EBP + 20] = error message for invalid input
;
; Returns: 
;		Registers changed: EAX, EBX, EDX, ESI
;--------------------------------------------------------
readVal PROC
	push	EBP
	mov		EBP, ESP
	push	ECX

_restart:

	mGetString [EBP + 8], [EBP + 12]	; get user input as string

	mov		ECX, EAX					; use length of string as counter
	mov		EAX, 0
	mov		ESI, [EBP + 12]
	mov		EDX, 0
	cld

	lodsb

	cmp		AL, 43						; sign check, skip if first character is a sign (+ or -)
	je		_skip
	cmp		AL, 45
	je		_skip
	jmp		_noSign						; if first char isn't a sign, skip past first lodsb of digit loop since it's already loaded

_digitLoop:
	lodsb

_noSign:
	cmp		AL, 48						; check if character is numeric
	jl		_invalid2
	cmp		AL, 57
	jg		_invalid2
	sub		AL, 48						; convert from ASCII to decimal

	push	EAX							; store current val while multiplying
	mov		EAX, EDX					; section multiplies previous total by 10 to mov decimal place
	mov		EBX, 10
	mul		EBX
	jo		_invalid1
	mov		EDX, EAX
	pop		EAX

	add		EDX, EAX
	jo		_invalid2

_skip:
	loop	_digitLoop

	cmp		AL, 43						; we need to check if the current value is +/- when the loop is done to ensure it was not the only char entered (and thus invalid)
	je		_invalid2
	cmp		AL, 45
	je		_invalid2

	jmp		_checkNeg

_invalid1:
	add		ESP, 4						; pop the value from the stack if invalid between EAX push and pop
_invalid2:
	mDisplayString [EBP + 20]
	call	CrLf
	jmp		_restart

_checkNeg:
	mov		ESI, [EBP + 12]				; go back to beginning of string and check for "-" sign, negate EDX if minus sign detected
	lodsb
	cmp		AL, 45
	jne		_end
	neg		EDX

_end:
	mov		EAX, EDX					; move final value to EAX and store in array
	stosd
	add		ESI, 4
	pop		ECX
	pop		EBP
	RET		12
readVal ENDP

;--------------------------------------------------------
; Name: writeVal
;
; Takes an integer value and prints it as a string to
; the console
;
; Preconditions: Requires integer value to be pushed,
; along with buffer for output string, and the "-"
; symbol to print negative if required
;
; Postconditions: Integer written to console
;
; Receives:
;		[EBP + 8]  = Value to be displayed
;		[EBP + 12] = output string
;		[EBP + 16] = minus symbol string
;
; Returns:
;		Registers changed: EAX, EBX
;--------------------------------------------------------
writeVal PROC
	push	EBP
	mov		EBP,ESP
	push	ECX
	push	EDI
	push	ESI
	push	EDX

	mov		EDI, [EBP + 12]				; add output string to EDI
	mov		EAX, [EBP + 8]				; store value in EAX
	mov		ECX, 10
	mov		EBX, 0						; count number of digits

	cmp		EAX, 0						; check if value is negative, if so negate it and print "-" symbol
	jns		_setDirectionFlag
	neg		EAX
	mDisplayString [EBP + 16]

_setDirectionFlag:
	std

_digitLoopWrite:
	inc		EBX							; add digit to count

	push	EBX							; divide number by ten, convert remainder to ASCII and store in array, repeat with result of previous division
	mov		EDX, 0
	mov		EBX, 10
	div		EBX
	pop		EBX

	push	EAX
	mov		EAX, EDX
	add		EAX, 48
	stosb
	pop		EAX

	cmp		EAX, 0						; check if EAX is 0 (string vals have all been pushed to the stack)
	je		_write
	loop	_digitLoopWrite

_write:
	add		EDI, 1						; add 1 to edi since the last iteration of stosb took us too far
	mDisplayString EDI

	pop		EDX
	pop		ESI
	pop		EDI
	pop		ECX
	pop		EBP
	RET 12
writeVal ENDP

;--------------------------------------------------------
; Name: displayList
;
; Prints array of integers to the console
;
; Preconditions: array must be of type DWORD
;
; Postconditions: array is printed
;
; Receives:
;		[EBP+8]  = title string
;		[EBP+12] = array to be printed
;		[EBP+16] = string for "space" char
;		[EBP+20] = output buffer
;		[EBP+24] = string for minus symbol
; Returns:
;		EAX, ECX, EDX, ESI
;--------------------------------------------------------
displayList PROC
	push	EBP
	mov		EBP, ESP
	mov		EDX, [EBP + 8]
	call	WriteString					; display intro text for context
	call	CrLf

	mov		ESI, [EBP + 12]
	mov		ECX, ARRAYSIZE				; use size of array as loop count
_nextElement:
	mov		EAX, [ESI]
	push	[EBP + 24]
	push	[EBP + 20]
	push	EAX
	call	writeVal
	add		ESI, 4
	cmp		ECX, 1
	je		_skipComma
	mov		EDX, [EBP + 16]				; write comma with space unless it is the last value in the array
	call	WriteString

_skipComma:					
	loop	_nextElement
	jmp		_end

_end:
	call	CrLf
	pop		EBP
	RET	24
displayList ENDP

;--------------------------------------------------------
; Name: sumArray
;
; Calculates sum of all elements in the array, prints
; the sum, and prints the rounded-down average of the
; sum
;
; Preconditions: array must be of type DWORD, title
; text for sum and sverage must be strings, minus
; symbol string must be pushed, buffer must be pushed
; for output string
;
; Postconditions: Sum and average are calculated and
; printed
;
; Receives:
;		[EBP + 8]  = array to be printed
;		[EBP + 12] = title text for sum
;		[EBP + 16] = title text for average
;		[EBP + 20] = minus symbol
;		[EBP + 24] = output string
; Returns:
;		Registers changed: EAX, EBX, ECX, EDX, ESI
;--------------------------------------------------------
sumArray PROC
	push	EBP
	mov		EBP, ESP

	mDisplayString [EBP + 12]			; display title for sum

	mov		ESI,[EBP + 8]
	mov		ECX, ARRAYSIZE				; use arraysize to count loop
	mov		EDX, 0						; store vals in EDX
	cld

_sumLoop:
	add		EDX, [ESI]					; iterate through values in array, add each to EDX to accumulate
	add		ESI, 4
	loop	_sumLoop

	push	[EBP + 20]					; call WriteVal on sum
	push	[EBP + 24]
	push	EDX
	call	WriteVal

	call	CrLf
	mDisplayString [EBP + 16]			; display title for average

	mov		EAX, EDX					; calculate average by dividing sum by ARRAYSIZE
	cdq
	mov		EBX, ARRAYSIZE
	idiv	EBX

	push	[EBP + 20]					; call WriteVal on average
	push	[EBP + 24]
	push	EAX
	call	WriteVal

	pop		EBP
	RET 20
sumArray ENDP

END main
