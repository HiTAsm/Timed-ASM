
asm ALU22

import StandardLibrary

signature:
	// DOMAINS
	domain UpdateRule subsetof Agent
	domain Register subsetof Integer
	domain Word subsetof Integer
	// FUNCTIONS
	controlled reg: Register -> Word
	monitored instr1 : Register
	monitored instr2 : Register
	monitored instr3 : Register
	controlled v1 : Word
	controlled v2 : Word
	controlled rd : Register

	static ur_r1 : UpdateRule
	static ur_r2 : UpdateRule
	static ur_r3 : UpdateRule
	static ur_wb: UpdateRule
	
	controlled min : Word
	controlled delay : UpdateRule -> Word
	controlled ct : Word
	
definitions:
	// DOMAIN DEFINITIONS
	domain Register = {0..31}
	domain Word = {0..255}

	// FUNCTION DEFINITIONS
	

	// RULE DEFINITIONS
	rule r_min =
		seq 
			choose $x in UpdateRule with delay($x) != 0 do
				min := delay($x)
			while (exist $y in UpdateRule with delay($y)!= 0 and  delay($y) <min) do
				choose $z in UpdateRule with  delay($z) != 0 do
					min :=  delay($z)
		endseq
	
	rule r_updateRule =
		switch (self)
			case ur_r3 : rd := instr1
			case ur_r1 : v1 := reg(instr2)
			case ur_r2 : v2 := reg(instr3)
			case ur_wb : if v1 + v2 <= 255 then
							skip
						endif
		endswitch
			
	
	rule r_updateDelay =
		delay(self) := switch (self)
			case ur_r3 : 2
			case ur_r1 : 2
			case ur_r2 : 2
			case ur_wb : 4
		endswitch
	
	rule r_delayedUpdateRule =
		par
			if delay(self) = min then
				r_updateRule[] 
			endif
			if delay(self) - min != 0 then
					delay(self):= delay(self) - min
			else r_updateDelay[]
			endif
		endpar
	// INVARIANTS
	//invariant over rd : rd != 0 
	// MAIN RULE
	main rule r_Main =
		par
			forall $x in UpdateRule do
			program($x)
			ct:= ct + min
		endpar

// INITIAL STATE
default init s0:
	function reg($a in Register) = $a
	function delay($x in UpdateRule) = switch $x
			case ur_r3 : 2
			case ur_r1 : 2
			case ur_r2 : 2
			case ur_wb : 4
		endswitch
	function min = 2
	function ct = 0
	agent UpdateRule :
		r_delayedUpdateRule[]
	
