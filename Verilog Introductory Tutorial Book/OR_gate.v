

/********************************************************************
 Title       : OR_gate.v	     		 
 Design      : A simple OR logic gate 
 Author      : David J. Marion		     	
 Func. Check : None
 Information : This module contains a 2-input OR gate
*********************************************************************/

//Begin a module description
module OR_gate(input A, input B, output O);	

wire A;		//Declare a wire that is input A
wire B;		//Declare a wire that is input B

wire O;		//Declare a wire that is output O

assign O = A | B;	//Tell Verilog what the value of O should be

endmodule			//End of module description