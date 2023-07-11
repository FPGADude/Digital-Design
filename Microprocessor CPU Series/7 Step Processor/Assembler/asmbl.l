/*************************************************************************************************/
/* asmbl.l - simple assembler lexical analyzer                                                   */
/*************************************************************************************************/


%option noyywrap
%option nounistd

%{

/* Include some important header files */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asmbl.tab.h"
#include "asmbl.h"

int label_index, number;
char lname[ 100 ];

%}

%%

LD|ST|ADD|SHR|SHL|NOT|AND|OR|XOR|CMP {
  IFDEBUG printf( "lexar found reg,reg mnemonic \xAB%s\xBB\n", yytext ); 
  current_opcode = mnemonic( yytext );
  memory[ current_address ] = current_opcode;
  num_operands = 0;
  return REG_REG_MNEMONIC; }

DATA { 
  IFDEBUG printf( "lexar found 2-operand opcode \xAB%s\xBB\n", yytext );
  current_opcode = mnemonic( yytext );
  memory[ current_address ] = current_opcode;
  num_operands = 0;
  return MNEMONIC2; }
  
JMP|JMPR|JA|JC|JE|JZ|IN|OUT {
  IFDEBUG printf( "lexar found 1-operand opcode \xAB%s\xBB\n", yytext );
  current_opcode = mnemonic( yytext );
  memory[ current_address ] = current_opcode;
  num_operands = 0;
  return MNEMONIC1; }
  
CLF {
  IFDEBUG printf( "lexar found 0-operand opcode \xAB%s\xBB\n", yytext );
  current_opcode = mnemonic( yytext );
  memory[ current_address ] = current_opcode;
  num_operands = 0;
  return MNEMONIC0; }

@?R[0-3]|r[0-3] {
  IFDEBUG printf( "lexar found a register \xAB%s\xBB\n", yytext );
  if( num_operands == 0 )
  {
    operand1 = register_name( yytext[ 0 ] == '@' ? yytext + 1 : yytext );
    if( operand1 >= 0 )
    {
      if( ( current_opcode == 0x20 ) ||   //Is this a DATA command?
          ( current_opcode == 0x30 ) ||   //or a JMPR command?
          ( current_opcode == 0x70 ) ||   //or IN command?
          ( current_opcode == 0x78 )    ) //or OUT command?
      {
        //for these commands, there is only one operand, must be Rn
        memory[ current_address ] |= operand1 & 0x03;
      }
      else
      { //for these commands, the first operand gets shifted left 2 bits, then expect another Rn
        memory[ current_address ] |= ( operand1 & 0x03 ) << 2;
      }
      num_operands = 1;
    }
  }
  else if( num_operands == 1 )
  {
    operand2 = register_name( yytext[ 0 ] == '@' ? yytext + 1 : yytext );
    if( operand2 >= 0 )
    {
      num_operands = 2;
      memory[ current_address ] |= operand2;
    }
  }
  if( ( ( current_opcode == 0x70 ) || 
        ( current_opcode == 0x78 )    ) && //for IN/OUT instructions
      ( yytext[ 0 ] == '@' )        )
    memory[ current_address ] |= 0x04;
  return REGNAME; }

[A-Za-z_][0-9A-Za-z_]*: { 
  strcpy( lname, yytext );
  lname[ strlen( lname ) - 1 ] = 0; //remove the trailing ':'
  IFDEBUG printf( "lexar found known label \xAB%s\xBB\n", lname ); 
  new_known_label( lname, current_address );
  return LABEL; }
                                
[A-Za-z_][0-9A-Za-z_]* {
  IFDEBUG printf( "lexar found forward label \xAB%s\xBB\n", yytext ); 
  if( ( current_opcode == 0x20 ) ||            //Is this a DATA command?
      ( current_opcode == 0x40 ) ||            //Is this a JMP command?
      ( ( current_opcode & 0xF0 ) == 0x50 ) )  //Is this a J? command?
  { //for the DATA command or JMP or J?, the label is the second byte
    current_address++;
    label_index = new_forward_label( yytext, current_address );
  }
  else if( current_opcode == 0x0101 )
  {
    //When inside a .BYTE, the label is stored at current address
    label_index = new_forward_label( yytext, current_address++ );
  }
  else if( current_opcode == 0x0102 )
  {
    label_index = new_forward_label( yytext, current_address++ );
    memory[ current_address++ ] = 0; //high byte will be 0
  }
  else if( current_opcode == 0x0104 )
  {
    label_index = new_forward_label( yytext, current_address++ );
    memory[ current_address++ ] = 0;
    memory[ current_address++ ] = 0;
    memory[ current_address++ ] = 0;
  }
  else if( current_opcode == 0x120 )
  {
    strcpy( lname, yytext ); //save the name of the label
  }
  return LABEL; }

;.* { 
  IFDEBUG printf( "lexar found a comment \xAB%s\xBB\n", yytext ); 
  return COMMENT; }
                                
\.[A-Za-z0-9]* { 
  IFDEBUG printf( "lexar found a directive \xAB%s\xBB\n", yytext );
  current_opcode = directive( yytext ); 
  if( current_opcode == 0x100 ) return ORG_DIRECTIVE;
  if( current_opcode == 0x101 ) return BYTE_DIRECTIVE;
  if( current_opcode == 0x102 ) return SHORT_DIRECTIVE;
  if( current_opcode == 0x104 ) return INT_DIRECTIVE; 
  if( current_opcode == 0x120 ) return EQU_DIRECTIVE; }

[0-9]+|0d[0-9]+ {
  IFDEBUG printf( "lexar found a decimal number \xAB%s\xBB\n", yytext );
  number = atoi( yytext[ 1 ] == 'd' ? yytext + 2 : yytext );
  if( ( current_opcode == 0x20 ) ||            //Is this a DATA command?
      ( current_opcode == 0x40 ) ||            //Is this a JMP command?
      ( ( current_opcode & 0xF0 ) == 0x50 ) )  //Is this a J? command?
  { //for the DATA command or JMP or J?, the number is the second byte
    current_address++;
    memory[ current_address ] = number;
  }
  else if( current_opcode == 0x0100 )
  {
    current_address = number;
  }
  else if( current_opcode == 0x0101 )
  {
    if( ( number > 255 ) || ( number < -128 ) )
      fprintf( stderr, "WARNING: number out of range in line %d\n", line_number );
    
    memory[ current_address++ ] = number & 0x0FF;
  }
  else if( current_opcode == 0x0102 )
  {
    if( ( number > 65535 ) || ( number < -32768 ) )
      fprintf( stderr, "WARNING: number out of range in line %d\n", line_number );
    
    memory[ current_address++ ] = number & 0x0FF;
    memory[ current_address++ ] = ( number >> 8 ) & 0x0FF;
  }
  else if( current_opcode == 0x0104 )
  {
    memory[ current_address++ ] = number & 0x0FF;
    memory[ current_address++ ] = ( number >> 8 ) & 0x0FF;
    memory[ current_address++ ] = ( number >> 16 ) & 0x0FF;
    memory[ current_address++ ] = ( number >> 24 ) & 0x0FF;
  }
  else if( current_opcode == 0x0120 )
  {
    IFDEBUG printf( "nkl(%s,%d)\n", lname, number );
    new_known_label( lname, number );
    //equate_label( lname, number );
  }
  return VALUE; }
  
0x[0-9A-Fa-f]+|\$[0-9A-Fa-f]+ {
  IFDEBUG printf( "lexar found a hexadecimal number \xAB%s\xBB\n", yytext );
  sscanf( yytext[ 1 ] == 'x' ? yytext + 2 : yytext+1, "%x", &number );
  if( ( current_opcode == 0x20 ) ||            //Is this a DATA command?
      ( current_opcode == 0x40 ) ||            //Is this a JMP command?
      ( ( current_opcode & 0xF0 ) == 0x50 ) )  //Is this a J? command?
  { //for the DATA command or JMP or J?, the number is the second byte
    current_address++;
    memory[ current_address ] = number;
  }
  else if( current_opcode == 0x0100 )
  {
    current_address = number;
  }
  else if( current_opcode == 0x0101 )
  {
    if( ( number > 255 ) || ( number < -128 ) )
      fprintf( stderr, "WARNING: number out of range in line %d\n", line_number );
    
    memory[ current_address++ ] = number & 0x0FF;
  }
  else if( current_opcode == 0x0102 )
  {
    if( ( number > 65535 ) || ( number < -32768 ) )
      fprintf( stderr, "WARNING: number out of range in line %d\n", line_number );
    
    memory[ current_address++ ] = number & 0x0FF;
    memory[ current_address++ ] = ( number >> 8 ) & 0x0FF;
  }
  else if( current_opcode == 0x0104 )
  {
    memory[ current_address++ ] = number & 0x0FF;
    memory[ current_address++ ] = ( number >> 8 ) & 0x0FF;
    memory[ current_address++ ] = ( number >> 16 ) & 0x0FF;
    memory[ current_address++ ] = ( number >> 24 ) & 0x0FF;
  }
  else if( current_opcode == 0x0120 )
  {
    IFDEBUG printf( "nkl(%s,%d)\n", lname, number );
    new_known_label( lname, number );
    //equate_label( lname, number );
  }
  return VALUE; }
  
0b[01]+|\%[01]+ {
  IFDEBUG printf( "lexar found a binary number \xAB%s\xBB\n", yytext );
  number = btoi( yytext[ 1 ] == 'b' ? yytext + 2 : yytext+1 );
  if( ( current_opcode == 0x20 ) ||            //Is this a DATA command?
      ( current_opcode == 0x40 ) ||            //Is this a JMP command?
      ( ( current_opcode & 0xF0 ) == 0x50 ) )  //Is this a J? command?
  { //for the DATA command or JMP or J?, the number is the second byte
    current_address++;
    memory[ current_address ] = number;
  }
  else if( current_opcode == 0x0100 )
  {
    current_address = number;
  }
  else if( current_opcode == 0x0101 )
  {
    if( ( number > 255 ) || ( number < -128 ) )
      fprintf( stderr, "WARNING: number out of range in line %d\n", line_number );
    
    memory[ current_address++ ] = number & 0x0FF;
  }
  else if( current_opcode == 0x0102 )
  {
    if( ( number > 65535 ) || ( number < -32768 ) )
      fprintf( stderr, "WARNING: number out of range in line %d\n", line_number );
    
    memory[ current_address++ ] = number & 0x0FF;
    memory[ current_address++ ] = ( number >> 8 ) & 0x0FF;
  }
  else if( current_opcode == 0x0104 )
  {
    memory[ current_address++ ] = number & 0x0FF;
    memory[ current_address++ ] = ( number >> 8 ) & 0x0FF;
    memory[ current_address++ ] = ( number >> 16 ) & 0x0FF;
    memory[ current_address++ ] = ( number >> 24 ) & 0x0FF;
  }
  else if( current_opcode == 0x0120 )
  {
    IFDEBUG printf( "nkl(%s,%d)\n", lname, number );
    new_known_label( lname, number );
    //equate_label( lname, number );
  }
  return VALUE; }
  
0o[0-7]+|@[0-7]+ {
  IFDEBUG printf( "lexar found an octal number \xAB%s\xBB\n", yytext );
  sscanf( yytext[ 1 ] == 'o' ? yytext + 2 : yytext+1, "%o", &number );
  if( ( current_opcode == 0x20 ) ||            //Is this a DATA command?
      ( current_opcode == 0x40 ) ||            //Is this a JMP command?
      ( ( current_opcode & 0xF0 ) == 0x50 ) )  //Is this a J? command?
  { //for the DATA command or JMP or J?, the number is the second byte
    current_address++;
    memory[ current_address ] = number;
  }
  else if( current_opcode == 0x0100 )
  {
    current_address = number;
  }
  else if( current_opcode == 0x0101 )
  {
    if( ( number > 255 ) || ( number < -128 ) )
      fprintf( stderr, "WARNING: number out of range in line %d\n", line_number );
    
    memory[ current_address++ ] = number & 0x0FF;
  }
  else if( current_opcode == 0x0102 )
  {
    if( ( number > 65535 ) || ( number < -32768 ) )
      fprintf( stderr, "WARNING: number out of range in line %d\n", line_number );
    
    memory[ current_address++ ] = number & 0x0FF;
    memory[ current_address++ ] = ( number >> 8 ) & 0x0FF;
  }
  else if( current_opcode == 0x0104 )
  {
    memory[ current_address++ ] = number & 0x0FF;
    memory[ current_address++ ] = ( number >> 8 ) & 0x0FF;
    memory[ current_address++ ] = ( number >> 16 ) & 0x0FF;
    memory[ current_address++ ] = ( number >> 24 ) & 0x0FF;
  }
  else if( current_opcode == 0x0120 )
  {
    IFDEBUG printf( "nkl(%s,%d)\n", lname, number );
    new_known_label( lname, number );
    //equate_label( lname, number );
  }
  return VALUE; }


\n {
  IFDEBUG printf( "lexar found EOL\n" );
  if( ( current_opcode < 0x100 ) && ( current_opcode > -1 ) ) current_address++;
  current_opcode = -1;
  line_number++; 
  return EOL; }

[ \t]*\r? { /* white space, ignore */ }

, { IFDEBUG printf( "lexar found ,\n" ); return COMMA; }

%%
