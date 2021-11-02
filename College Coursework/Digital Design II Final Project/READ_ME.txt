*************************************************
*						*
*	Traffic Controller Information		*
*						*
*************************************************

*RUN Marion_traffic_controller.bat to run the traffic controller
*Then in command line type vvp traffic_controller
*Then type gtkwave traffic_controller_TB.vcd

*Must have installed Icarus Verilog and GTKWave

**SEE traffic_controller.pptx for traffic light
	and countdown segment displays and timer mode 
	and sensor mode state diagrams.

***Some test benches are included, but not all were tested individually.

****See schematics for timer mode, sensor mode, and traffic controller.
No schematic included for Light Control as it is a big mess of wires
and logic gates. 

The traffic controller circuit has six inputs that control the outputs
to all traffic lights, including walk, don't walk, and don't walk 
countdown light segments.

Inputs:
1. 24 hour clock that outputs a signal that changes at 6 am and 9 pm. 
1 = timer mode, 0 = sensor mode
2. Synchronizing clock
3. A reset button.
4. An emergency switch for operators and emergency personnel.
5. Push button to walk across street in sensor mode.
6. Pressure sensor to detect a vehicle in sensor mode.

_______________________________________________________
Module heirarchy:

traffic_controller.v	<------TOP MODULE
	light_control.v	
	timer_mode.v				
		light_fsm.v
		light_decoder.v
		wdwt_decoder_Maj.v
		wdwt_decoder_min.v
		counter1.v
		counter4.v
		counter6.v
	sensor_mode.v
		light_fsm2.v
		light_decoder2.v
		wdws_decoder.v
		srl.v
		counter2.v
		counter3.v
		counter5.v
		
18 total modules
________________________________________________________

Timing chart:

--Timer mode-- (60 second cycle)
begin
  t=0	state 0  *DON'T WALK across Major or Minor St.
	1	state 1
	2
	3
	4
	5
	6
	7
	8	state 2
	9
	10
	11	state 3		*WALK across Minor St.
	12	
	13	
	14	
	15	
	16	
	17
	18
	19
	20
	21
	22
	23
	24
	25	*DON'T WALK across Minor St. countdown begins
	26
	27
	28
	29
	30
	31
	32 	state 4
	33
	34
	35	state 5		*DON'T WALK across Minor St.
	36	state 6
	37
	38
	39
	40
	41
	42	state 7
	43
	44
	45	state 8		*WALK across Major St.
	46
	47
	48
	49
	50	* DON'T WALK across Major St. countdown begins
	51
	52
	53
	54
	55
	56
	57	state 9
	58
	59
end		return to state 0

--Sensor Mode-- (16 second cycle)
begin
  t=0	state 0  *DEFAULT: DON'T WALK across Major St., WALK across Minor St.
*Advance only if WALK button or CAR sensor is pulsed.
	1	
	2	state 1	*DON'T WALK across Minor St.
	3
	4
	5	state 2
	6	state 3	*DON'T WALK across Major St. countdown begins
	7
	8	
	9
	10
	11	
	12	
	13	state 4
	14	
	15
end 	return to state 0

Design Trade/Offs:
	CONCERNING ONLY SENSOR MODE
	During sensor mode, there may be an instance of a pedestrian walking across
	Minor St. when suddenly the DON'T WALK sign appears. This was necessary to
	keep sensor mode short. Also, there is no WALK across Major St. The go ahead
	to walk across Major St. when the button is pressed begins at the DON'T WALK
	countdown sequence. A pedestrian has exactly 10 seconds to cross Major ST.
	An instance of the WALK sign before the DON'T WALK countdown begins can be 
	added which would only add one second to sensor mode.
________________________________________________________	