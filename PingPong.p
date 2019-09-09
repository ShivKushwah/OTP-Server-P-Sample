event Ping assert 1: machine;
event Pong assert 1: machine;
event Msg assert 1: int;
event OTPSecret assert 1: (machine, int);
event OTPSecretReceived;
event OTPCode assert 1: int;
event OTPCodeValidated;


event Success;
event M_Ping;
event M_Pong;

machine PING 
{
    var pongMachine: machine;

    // This is the entry point.
    start state Init {
        entry (payload:any) {
          pongMachine = payload as machine;
          raise (Success);   	   
        }
        on Success goto GenerateOTPSecret;
    }

    state GenerateOTPSecret {
        entry {
			// generate OTP secret 
			// var secret: StringType;
			send pongMachine, OTPSecret, (this, 3);
	    }
        on OTPSecretReceived goto WaitOTPCode;
     }

     state WaitOTPCode {
        on OTPCode goto ValidateOTPCode;
     }

	 state ValidateOTPCode {
        entry (payload: int) {
          send pongMachine, OTPCodeValidated;
          raise (Success);   	   
        }
		on Success goto Done;
     }

     state Done {}
}

machine PONG
{
	var pingMachine : machine;

    start state Init {
        on OTPSecret goto WaitOTPSecret;
    }

    state WaitOTPSecret {
	    entry (payload: (machine, int)) {
	        pingMachine = payload.0;
			send pingMachine, OTPSecretReceived;
			raise (Success);	 	  
	    }
        on Success goto GenerateOTPCode;
    }

	state GenerateOTPCode {
	    entry {
			send pingMachine, OTPCode, 7;
	    }
        on OTPCodeValidated goto End;
    }
	
	state End {
		entry {
			raise(halt);
		}
	}
}

spec M observes M_Ping, M_Pong {
    start state ExpectPing {
        on M_Ping goto ExpectPong;
    }

	state ExpectPong {
        on M_Pong goto ExpectPing;
    }
}

fun _CREATEMACHINE(cner: machine, typeOfMachine: int, param : any, newMachine: machine) : machine
{
	if(typeOfMachine == 1)
	{
		newMachine = new PING(param);
	}
	else if(typeOfMachine == 2)
	{
		newMachine = new PONG();
	}
	else
	{
		assert(false);
	}
	return newMachine;
}

machine GodMachine
{
	var container : machine;
    var pongMachine: machine;

    start state Init {
	    entry {
			container = _CREATECONTAINER();
			pongMachine = _CREATEMACHINE(container, 2, null, null as machine);
			container = _CREATECONTAINER();
			_CREATEMACHINE(container, 1, pongMachine, null as machine);
	    }
	}
}
