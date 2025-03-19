.386P
.model flat, stdcall
option casemap: none

extern VirtualAlloc@16: proc
extern VirtualFree@12: proc
extern MessageBoxA@16: proc
extern ExitProcess@4: proc
extern wsprintfA: proc

.data
	buff_size dd 1024
	buffer dd 0
	count dd 256
	caption db "Info", 0
	format db "%d", 0
	output db 256 dup(0)
	dynamic_format db 256 dup(0)

.code
memset proc
	push ebp
	mov ebp, esp

	push edi
	mov edi, [ebp + 8]	; dst
	mov eax, [ebp + 12]	; value
	mov ecx, [ebp + 16]	; count

	cld
	rep stosb
	mov eax, [ebp + 8]

	pop edi
	pop ebp
	ret
memset endp

generate_format proc
	push ebp
	mov ebp, esp
	
	push esi
	push edi
	push ebx
	
	mov esi, offset format;
	mov edi, offset dynamic_format;
	mov ecx, [ebp + 8];
	
	cld
	copy_loop:
		lodsb
		stosb
		test al, al
		jnz copy_loop
	
	dec edi
	dec ecx
	jz done
	format_loop:
		mov al, ' '
		stosb
		mov al, '%'
		stosb
		mov al, 'd'
		stosb
		loop format_loop
	
	done:
	mov byte ptr[edi], 0
	
	pop ebx
	pop edi
	pop esi
	
	pop ebp
	ret
generate_format endp

sprintf_s proc
	push ebp
	mov ebp, esp

	push esi
	push edi
	push ebx

	mov edi, [ebp + 8] ; output
	mov esi, [ebp + 12] ; format
	mov ebx, [ebp + 16] ; ptr buffer
	mov ecx, [ebp + 20] ; count

	lea eax, [ebx + ecx * 4 - 4]
	push_loop:
		push dword ptr[eax]
		sub eax, 4
		loop push_loop

	push esi
	push edi
	call wsprintfA

	mov ecx, [ebp + 20]
	add ecx, 2;
	shl ecx, 2
	add esp, ecx

	pop ebx
	pop edi
	pop esi

	pop ebp
	ret
sprintf_s endp

start:
	push 4h
	push 1000h
	push buff_size
	push 0
	call VirtualAlloc@16
	test eax, eax
	jz exit

	mov buffer, eax
	xor eax, eax

	push buff_size
	push 0
	push buffer
	call memset

	mov eax, buffer
	mov ecx, count
	mov ebx, 0
	write_loop:
		mov dword ptr[eax], ebx
		add eax, 4
		inc ebx
		loop write_loop

	push count
	call generate_format
	add esp, 4

	push count
	push buffer
	push offset dynamic_format
	push offset output
	call sprintf_s

	push 0
	push offset caption
	push offset output
	push 0
	call MessageBoxA@16

	push 8000h
	push 0
	push buffer
	call VirtualFree@12

exit:
	push 0
	call ExitProcess@4
	ret
end start