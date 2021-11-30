

/********************************************************************
 Title       : AND_gate.v	     		 
 Design      : A simple AND logic gate 
 Author      : David J. Marion		     	
 Func. Check : Complete
 Information : This module contains a 2-input AND gate
*********************************************************************/

//5. Tell Verilog how to determine the output O

//Begin a module description
module AND_gate(input A, input B, output O);	

wire A;		//Declare a wire that is input A
wire B;		//Declare a wire that is input B

wire O;		//Declare a wire that is output O

assign O = A & B;	//Tell Verilog what the value of O should be

endmodule			//End of module description