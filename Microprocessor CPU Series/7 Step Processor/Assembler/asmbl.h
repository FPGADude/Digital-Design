/*************************************************************************************************/
/* asmbl.l - simple assembler                                                                    */
/*************************************************************************************************/

#ifndef _ASMBL_H_
#define _ASMBL_H_

/*************************************************************************************************/
/* Constant data definitions                                                                     */
/*************************************************************************************************/

#define LABEL_LENGTH 32
#define MAX_LABELS   100
#define IFDEBUG      if( debug_mode == 1 )

/*************************************************************************************************/
/* Global data space - Bad programming style, but, eh - whatcha gonna do?                        */
/*************************************************************************************************/

typedef enum { BINARY=0, INTEL, MOTOROLA } out_type;

typedef struct struct_label_type
{
  char name[ LABEL_LENGTH ];   //name of label
  unsigned int location;       //value of label
           int assigned;       //0=unassigned, 1=assigned
           int linkage[ 100 ]; //Addresses referencing this label, or -1
  unsigned int references;     //number of references in lingage table
} label;

extern unsigned int debug_mode;           //display ugly debugging info
extern unsigned int listing;              //output listing of assembly

extern unsigned char current_address;     //address assembly output is going into
extern int           current_opcode;      //8-bit opcode or 16-bit directive
extern int           operand1, operand2;  //operand values
extern unsigned int  num_operands;        //number of operands on this line so far
extern unsigned int  line_number;         //line number in current source file

extern unsigned char memory[ 256 ];       //256-byte memory image

extern label labels[ MAX_LABELS ];        //list of labels
extern int   num_labels;                  //number of labels

extern FILE *infile, *outfile, *listfile;

/*************************************************************************************************/
/* function prototypes                                                                           */
/*************************************************************************************************/

int new_known_label( char *name, int location );       //when the location is known
int new_forward_label( char *name, int link_me );      //when the location is unknown
int find_label( char *name );                          //look for a label
int add_reference_to_label( char *name, int link_me ); //add a reference to a label
int equate_label( char *name, int value );             //assign a value to a label

int mnemonic( char *word );                            //text-to-opcode
int directive( char *word );                           //text-to-directive code
int register_name( char *word );                       //Rn or @Rn register number

int btoi( char *string );                              //0b#### or %#### ASCII to binary

int show_labels( void );                               //display the list of labels
int place_labels( void );                              //update (link) labels in memory
int show_memory( void );                               //display the program memory

int write_output( void );                              //write the program memory to the output file

#endif
