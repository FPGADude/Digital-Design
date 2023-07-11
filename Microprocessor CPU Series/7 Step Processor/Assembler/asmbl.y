/*************************************************************************************************/
/* asmbl.y - simple assembler syntax analyzer and most of the 'C' code                           */
/*************************************************************************************************/

%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asmbl.h"

/*************************************************************************************************/
/* Global data space - Bad programming style, but, eh - whatcha gonna do?                        */
/*************************************************************************************************/

unsigned int debug_mode = 0; //display ugly debugging info
unsigned int listing = 0;    //output listing of assembly
out_type     out_format = BINARY; //How to format the output

unsigned char current_address;
int           current_opcode;
int           operand1, operand2;
unsigned int  num_operands;
unsigned int  line_number;

unsigned char memory[ 256 ];

label labels[ MAX_LABELS ];
int   num_labels;

char infile_name[ 100 ], outfile_name[ 100 ], listfile_name[ 100 ];
FILE *infile, *outfile, *listfile;

%}

 //%define parse.error verbose

%token REG_REG_MNEMONIC LABEL MNEMONIC0 MNEMONIC1 MNEMONIC2 OPERAND COMMENT VALUE REGNAME COMMA  EOL
%token BYTE_DIRECTIVE SHORT_DIRECTIVE INT_DIRECTIVE ORG_DIRECTIVE EQU_DIRECTIVE

%%

program: /* NULL */
  | statement_list { }
  ;

statement_list: statement { IFDEBUG printf( "Single statement\n" ); }
  | statement statement_list { IFDEBUG printf( "Recursive statement\n" ); }
  ;

statement: EOL { }
  | LABEL optional_comment EOL { IFDEBUG printf( "LABEL\n" ); }
  | COMMENT EOL { IFDEBUG printf( "COMMENT\n" ); }
  | directive_statement EOL { IFDEBUG printf( "DIRECTIVE_STATEMENT\n" ); }
  | dataset_statement EOL { IFDEBUG printf( "DATASET list STATEMENT\n" ); }
  | regreg_statement EOL { IFDEBUG printf( "OPC R,R\n" ); }
  | optional_label MNEMONIC0 optional_comment EOL { IFDEBUG printf( "CMD\n" ); }
  | optional_label MNEMONIC1 operand optional_comment EOL { IFDEBUG printf( "CMD (1)\n" ); }
  | optional_label MNEMONIC2 REGNAME COMMA operand optional_comment EOL { IFDEBUG printf( "CMD (2)\n" ); }
  ;

optional_label: /* NULL */ {}
  | LABEL { IFDEBUG printf( "Label\n" );}
  ;

optional_comment: /* NULL */ {}
  | COMMENT { IFDEBUG printf( "(comment)\n" ); }
  ;

operand: REGNAME { IFDEBUG printf( "Operand is REG\n" );}
  | VALUE { IFDEBUG printf( "Operand is label\n" ); }
  | LABEL { IFDEBUG printf( "Operand is label" ); }
  ;

arglist: arg { IFDEBUG printf( "ARG\n" ); }
  | arg COMMA arglist { IFDEBUG printf( "ARG list\n" ); }
  ;

arg: VALUE { IFDEBUG printf( "VALUE_ARG\n" ); }
  | LABEL { IFDEBUG printf( "LABEL_ARG\n" ); }
  ;

directive_statement: org_statement { IFDEBUG printf( ".ORG\n" ); }
  | equ_statement { IFDEBUG printf( ".EQU\n" ); }
  ;

org_statement: optional_label ORG_DIRECTIVE VALUE optional_comment { IFDEBUG printf( "ORG DIRECTIVE\n" ); } ;
equ_statement: optional_label EQU_DIRECTIVE LABEL COMMA VALUE optional_comment { IFDEBUG printf( "EQU DIRECTIVE\n" ); } ;
dataset_statement: optional_label dataset_directive arglist optional_comment { IFDEBUG printf( "DATA DIRECTIVE with list\n" ); } ;

dataset_directive: BYTE_DIRECTIVE { IFDEBUG printf( ".BYTE\n" ); }
  | SHORT_DIRECTIVE { IFDEBUG printf( ".SHORT\n" ); }
  | INT_DIRECTIVE { IFDEBUG printf( ".INT\n" ); }
  ;

regreg_statement: optional_label REG_REG_MNEMONIC REGNAME COMMA REGNAME optional_comment { IFDEBUG printf( "OPC R,R statement\n"); } ;

%%

/*===============================================================================================*/
/* find_label - find a label in the label list                                                   */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  name is a char pointer to the string to look for                                      */
/* Output: if the label is found, return the index into the table.  If not, return -1            */
/*===============================================================================================*/
int find_label( char *name )
{
  int status = -1;
  int loop;
  
  for( loop = 0; loop < MAX_LABELS; loop++ )
  {
    if( strcmp( name, labels[ loop ].name ) == 0 ) break;
  }
  
  if( loop < MAX_LABELS )
    status = loop;
  
  
  return status;
}

/*===============================================================================================*/
/* new_known_label - add a label with a known location or value                                  */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  name is a char pointer to the string of the label name                                */
/*         location is an int that is the address or value associated with the label             */
/* Output: if the label is found or created, return the index of the label.  If fail, return -1  */
/*===============================================================================================*/
int new_known_label( char *name, int location )
{
  int status;
  int loop;
  
  status = find_label( name );
  if( status >= 0 ) //if found in list already
  {
    if( labels[ status ].assigned ) 
      fprintf( stderr, "WARNING: Label %s already defined, being redefined in line %d?\n", name, line_number );
    labels[ status ].location = location;
    labels[ status ].assigned = 1;
    //labels[ status ].references = 0;
  }
  else //if not found in the existing list
  {
    if( num_labels < MAX_LABELS ) //only if room for new labels
    {
      strcpy( labels[ num_labels ].name, name );
      labels[ num_labels ].location = location;
      labels[ num_labels ].assigned = 1;
      for( loop = 0; loop < 100; loop++ )
        labels[ num_labels ].linkage[ loop ] = -1;
      labels[ num_labels ].references = 0;
      status = num_labels;
      num_labels++;
    }
  }
  
  return status;
}

/*===============================================================================================*/
/* new_forward_label - add a label with an yet unknown location or value                         */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  name is a char pointer to the string of the label name                                */
/*         link_me is an int containint the address of the opcode where the label is referenced  */
/* Output: if the label is found or created, return the index of the label.  If fail, return -1  */
/*===============================================================================================*/
int new_forward_label( char *name, int link_me )
{
  int status;
  int loop;
  
  status = find_label( name );
  if( status > -1 ) //if found in the list already
  {
    labels[ status ].linkage[ labels[ status ].references++ ] = link_me;
  }
  else //new label to be added
  {
    strcpy( labels[ num_labels ].name, name );
    labels[ num_labels ].location = 0xFFFFFFFF; //unknown location
    labels[ num_labels ].assigned = 0;
    labels[ num_labels ].linkage[ 0 ] = link_me;
    for( loop = 1; loop < 100; loop++ )
      labels[ num_labels ].linkage[ loop ] = -1;
    labels[ num_labels ].references = 1;
    status = num_labels;
    num_labels++;
  }
  
  return status;
}

/*===============================================================================================*/
/* add_reference_to_label - add a reference to a label                                           */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  name is a char pointer to the string of the label name                                */
/*         link_me is an int containint the address of the opcode where the label is referenced  */
/* Output: if the label is found or created, return the index of the label.  If fail, return -1  */
/*===============================================================================================*/
int add_reference_to_label( char *name, int link_me )
{
  int status = find_label( name );
  
  if( status > -1 ) //if found in list
  {
    if( labels[ status ].references < 100 )
    {
      labels[ status ].references++;
    }
    else //too many references
    {
      fprintf( stderr, "Too many renferences to %s\n", labels[ status ].name );
      status = -2;
    }
  }
  else //not found
  {
    status = new_forward_label( name, link_me );
  }
  
  return status;
}

/*===============================================================================================*/
/* equate_label - assign a value to a known label                                                */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  name is a char pointer to the string of the label name                                */
/*         value is an int that is the value to assign to the label                              */
/* Output: if the label is unknown, return -1.  Otherwise, return the index of the label         */
/*===============================================================================================*/
int equate_label( char *name, int value )
{
  int status = find_label( name );
  
  if( status > -1 )
  {
    labels[ status ].location = value;
    labels[ status ].assigned = 1;
  }
  
  return status;
}

/*===============================================================================================*/
/* mnemonic - convert mnemonic (string) to opcode (binary)                                       */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  word is a char pointer to the string of the mnemonic                                  */
/* Output: return the opcode (8-bit binary) or -1 if invalid word                                */
/*===============================================================================================*/
int mnemonic( char *word )
{
  int status=-1;
  
  if( strcmp( word, "LD" ) == 0 )
  {
    status = 0;
  }
  else if( strcmp( word, "ST" ) == 0 )
  {
    status = 0x10;
  }
  else if( strcmp( word, "DATA" ) == 0 )
  {
    status = 0x20;
  }
  else if( strcmp( word, "JMPR" ) == 0 )
  {
    status = 0x30;
  }
  else if( strcmp( word, "JMP" ) == 0 )
  {
    status = 0x40;
  }
  else if( strcmp( word, "JA" ) == 0 )
  {
    status = 0x54;
  }
  else if( strcmp( word, "JC" ) == 0 )
  {
    status = 0x58;
  }
  else if( strcmp( word, "JE" ) == 0 )
  {
    status = 0x52;
  }
  else if( strcmp( word, "JZ" ) == 0 )
  {
    status = 0x51;
  }
  else if( strcmp( word, "CLF" ) == 0 )
  {
    status = 0x60;
  }
  else if( strcmp( word, "IN" ) == 0 )
  {
    status = 0x70;
  }
  else if( strcmp( word, "OUT" ) == 0 )
  {
    status = 0x78;
  }
  else if( strcmp( word, "ADD" ) == 0 )
  {
    status = 0x80;
  }
  else if( strcmp( word, "SHR" ) == 0 )
  {
    status = 0x90;
  }
  else if( strcmp( word, "SHL" ) == 0 )
  {
    status = 0xA0;
  }
  else if( strcmp( word, "NOT" ) == 0 )
  {
    status = 0xB0;
  }
  else if( strcmp( word, "AND" ) == 0 )
  {
    status = 0xC0;
  }
  else if( strcmp( word, "OR" ) == 0 )
  {
    status = 0xD0;
  }
  else if( strcmp( word, "XOR" ) == 0 )
  {
    status = 0xE0;
  }
  else if( strcmp( word, "CMP" ) == 0 )
  {
    status = 0xF0;
  }
  else
  {
    fprintf( stderr, "Unknown assembly opcode: %s\n", word );
  }
  
  return status;
}

/*===============================================================================================*/
/* directive - convert string to directive code                                                  */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  word is a char pointer to the string of the directive                                 */
/* Output: return the directive code or -1 if invalid directive                                  */
/*===============================================================================================*/
int directive( char *word )
{
  int status = -1;
  
  if( strcmp( word, ".ORG" ) == 0 )
  {
    status = 0x100;
  }
  else if( strcmp( word, ".BYTE" ) == 0 )
  {
    status = 0x101;
  }
  else if( strcmp( word, ".SHORT" ) == 0 )
  {
    status = 0x102;
  }
  else if( strcmp( word, ".INT" ) == 0 )
  {
    status = 0x014;
  }
  else if( strcmp( word, ".ASCII" ) == 0 )
  {
    status = 0x110;
  }
  else if( strcmp( word, ".EQU" ) == 0 )
  {
    status = 0x120;
  }
  else
  {
    fprintf( stderr, "Unknown directive: %s\n", word );
  }
  
  return status;
}

/*===============================================================================================*/
/* register_name - convert a register name string to register number (2-bit binary)              */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  word is a char pointer to the string of the register name                             */
/* Output: return 0-3 if a valid register, or -1 if error                                        */
/*===============================================================================================*/
int register_name( char *word )
{
  int status = -1;
  
  if( ( word[ 1 ] < 0x34 ) && ( word[ 1 ] > 0x2F ) )
  {
    status = (int)( word[ 1 ] - 0x30 );
  }
  else
  {
    fprintf( stderr, "ERROR: Illegal register identifier: %s\n", word ); 
  }
  
  return status;
}

/*===============================================================================================*/
/*===============================================================================================*/
yyerror( char *s )
{
  fprintf( stderr, "yyerror: %s encountered at line %d\a\n", s, line_number );
}

/*===============================================================================================*/
/*===============================================================================================*/
int parse_parameters( int argc, char **argv )
{
  int loop;
  char *where;
  
  for( loop=1; loop<argc; loop++ ) //Do not process argv[0]
  {
    if( ( strcmp( argv[ loop ], "-d" ) == 0 )      ||
        ( strcmp( argv[ loop ], "-d+" ) == 0 )     ||
        ( strcmp( argv[ loop ], "/d" ) == 0 )      ||
        ( strcmp( argv[ loop ], "/d+" ) == 0 )    ||
        ( strcmp( argv[ loop ], "--debug" ) == 0 ) ||
        ( strcmp( argv[ loop ], "/debug" ) == 0  )    ) //enter debug mode
    {
      debug_mode = 1;
    }
    else if( ( strcmp( argv[ loop ], "-d-" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/d-" ) == 0 ) ||
             ( strcmp( argv[ loop ], "--nodebug" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/nodebug" ) == 0  )    ) //exit debug mode
    {
      debug_mode = 0; //default
    }
    else if( ( strcmp( argv[ loop ], "-l" ) == 0 )      ||
        ( strcmp( argv[ loop ], "-l+" ) == 0 )     ||
        ( strcmp( argv[ loop ], "/l" ) == 0 )      ||
        ( strcmp( argv[ loop ], "/l+" ) == 0 )    ||
        ( strcmp( argv[ loop ], "--list" ) == 0 ) ||
        ( strcmp( argv[ loop ], "/list" ) == 0  )    ) //enable_listing
    {
      listing = 1;
    }
    else if( ( strcmp( argv[ loop ], "-l-" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/l-" ) == 0 ) ||
             ( strcmp( argv[ loop ], "--nolist" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/nolist" ) == 0  )    ) //disable listing
    {
      listing = 0; //default
    }
    else if( ( strcmp( argv[ loop ], "-i" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/i" ) == 0 ) ||
             ( strcmp( argv[ loop ], "--intel" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/intel" ) == 0 )     ) //Intel output format
    {
      //out_format = INTEL;
      fprintf( stderr, "INTEL output format not yet implimented\n" );
    }
    else if( ( strcmp( argv[ loop ], "-m" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/m" ) == 0 ) ||
             ( strcmp( argv[ loop ], "--motorola" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/motorola" ) == 0 )     ) //Motorola output format
    {
      //out_format = MOTOROLA;
      fprintf( stderr, "MOTOROLA output format not yet implimented\n" );
    }
    else if( ( strcmp( argv[ loop ], "-b" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/b" ) == 0 ) ||
             ( strcmp( argv[ loop ], "--binary" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/binary" ) == 0 )     ) //Binary output format
    {
      out_format = BINARY; //default
    }
    else //Sure do hope this in an input file name!
    {
      strcpy( infile_name, argv[ loop ] );
      strcpy( outfile_name, argv[ loop ] );
      strcpy( listfile_name, argv[ loop ] );
      where = strstr( outfile_name, ".ASM" );
      if( !where ) where = strstr( outfile_name, ".asm" );
      if( !where )
      {
        fprintf( stderr, "Hmmm, I am assuming \"%s\" is an input file name.\n", infile_name );
        fprintf( stderr, "I was expecing it to in in \".ASM\" but since it doesn't, your output name will be weird.\n" );
        strcat( outfile_name, ".out" );
      }
      else
      {
        switch( out_format )
        {
          case BINARY:
            strcpy( where, ".bin" );
            break;
        
          case INTEL:
            strcpy( where, ".hex" );
            break;
        
          case MOTOROLA:
            strcpy( where, ".s19" );
            break;
        
          default:
            fprintf( stderr, "Unknown output format: %d, Cowardly aborting!\n", (int)out_format );
            return -1; //exit ugly!
        }
      }
      infile = fopen( infile_name, "r" );
      if( infile )
      {
        if( out_format == BINARY )
        {
          outfile = fopen( outfile_name, "wb" );
          if( outfile == NULL )
          {
            fclose( infile );
            fprintf( stderr, "Unable to output to binary file \"%s\" so I quit!\n", outfile_name );
            return -3;
          }  
        }
        else
        {
          outfile = fopen( outfile_name, "w" );
          if( outfile == NULL )
          {
            fclose( infile );
            fprintf( stderr, "Unable to output to file \"%s\" so I quit!\n", outfile_name );
            return -3;
          }
        }
        
        //At this point, both files are open
        if( listing )
        {
          where = strstr( listfile_name, ".ASM" );
          if( where == NULL ) where = strstr( listfile_name, ".asm" );
          if( where == NULL )
            strcat( listfile_name, ".lst" );
          else
            strcpy( where, ".lst" );
          
          listfile = fopen( listfile_name, "w" );
          if( listfile_name == NULL )
          {
            listing = 0;
            fprintf( stderr, "Unable to open listing file for output; continuing, but turning off listing.\n" );
          }
        }
        
        //Whew! Now, actually process the file!
        yyrestart( infile );
        num_labels = 0;
        current_address = 0;
        current_opcode = -1;
        line_number = 0;
        yyparse();
        show_labels();
        place_labels();
        show_memory();

        write_output();
        
        if( listing ) fclose( listfile );
        fclose( outfile );
        fclose( infile );
        outfile = stdout;
        
      }
      else
      {
        fprintf( stderr, "Unable to read \"%s\" so I quit!\n", infile_name );
        return -2;
      }
      
    }
  }
}


/*===============================================================================================*/
/* show_labels - print out the list of labels and their general information                      */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  -NONE-                                                                                */
/* Output: Return int value that is the number of labels                                         */
/*===============================================================================================*/
int show_labels( void )
{
  int loop, loop1;
  
  printf( "Labels (%d):\n", num_labels );
  for( loop = 0; loop < num_labels; loop++ )
  {
    printf( "%c %2d: %-20s %04X %d", labels[ loop ].assigned == 0 ? '*' : ' ',
      loop, labels[ loop ].name, labels[ loop ].location, labels[ loop ].references ); 
    for( loop1 = 0; loop1 < labels[ loop ].references; loop1++ )
      printf( "[%X] ", labels[ loop ].linkage[ loop1 ] );
    printf( "\n" );
  }
  printf( "\n" );
  
  return num_labels;
}

/*===============================================================================================*/
/* place_labels - place the label values into memory                                             */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  -NONE-                                                                                */
/* Output: Return int value that is the number of labels, or -1 if any labels are undefined      */
/*===============================================================================================*/
int place_labels( void )
{
  int label_loop, reference_loop;
  int status = num_labels;
  
  for( label_loop = 0; label_loop < num_labels; label_loop++ )
  {
    if( labels[ label_loop ].assigned )
    {
      for( reference_loop = 0; reference_loop < labels[ label_loop ].references; reference_loop++ )
        memory[ labels[ label_loop ].linkage[ reference_loop ] ] = labels[ label_loop ].location;
    }
    else
    {
      printf( "ERROR: Label %s is undefined.\n", labels[ label_loop ].name );
      status = -1;
    }
  }
  
  return status;
}

/*===============================================================================================*/
/* btoi - convert "########" from ASCII to binary integer                                        */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  string is a char pointer to the string to convert                                     */
/* Output: return the integer value                                                              */
/*===============================================================================================*/
int btoi( char *string )
{
  int value;
  
  value = 0;
  while( *string )
  {
    value = ( value << 1 ) | ( *string++ & 0x01 );
  }
  
  return value;
}

/*===============================================================================================*/
/* show_memory - display the 256-byte contents of memory in HEX                                  */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  -NONE-                                                                                */
/* Output: return 0                                                                              */
/*===============================================================================================*/
int show_memory( void )
{
  int loop;
  
  printf( "Memory:\n" );
  for( loop = 0; loop < 256; loop++ )
  {
    if( ( loop > 0 ) && ( ( loop & 0x0F ) == 0 ) ) printf( "\n" );
    if( ( loop & 0x0F ) == 0 ) printf( "%02X: ", loop );
    printf( "%02X ", memory[ loop ] );
  }
  printf( "\n" );

  return 0;
}

/*===============================================================================================*/
/* write_output - write output to the binary file                                                */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  -NONE-                                                                                */
/* Output: Return int value that is the length of memory written                                 */
/*===============================================================================================*/
int write_output( void )
{
  int count, file_no = fileno( outfile );
  
  if( out_format == BINARY )
  {
    count = write( file_no, memory, current_address );
  
    if( count != current_address ) count = -1;
  }
  else if( out_format == INTEL )
  {
    printf( "WARNING: INTEL output format not implmented yet.  Try BINARY instead.\n" );
    count = -2;
  }
  else if( out_format == MOTOROLA )
  {
    printf( "WARNING: MOTOROLA output format not implmented yet.  Try BINARY instead.\n" );
    count = -2;
  }
  else
    fprintf( stderr, "ERROR: Unknown output format.  No ountput generated\n" );
  
  return count;
}

/*===============================================================================================*/
/*===============================================================================================*/
int main( int argc, char **argv )
{
  parse_parameters( argc, argv );
  
  return 0;
}

