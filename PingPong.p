event Ping assert 1: machine;
event Pong assert 1: machine;
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
        on Success goto initCommunication;
    }

	state initCommunication {
        entry {
			announce M_Ping;
			// generate OTP secret 
			// var secret: StringType;
			_SEND(pongMachine, Ping, this);
	    }
        on Pong goto SendOTPSecret;
     }

    state SendOTPSecret {
        entry {
			announce M_Ping;
			// generate OTP secret 
			// var secret: StringType;
			_SEND(pongMachine, Ping, this);
			raise (Success);
	    }
        on Success goto WaitPong;
     }

     state WaitPong {
        on Pong goto Done;
     }

     state Done {}
}

machine PONG
{
	var pingMachine : machine;

    start state Init {
        on Ping goto initCommunication;
    }

	state initCommunication {
		 entry (payload: machine) {
	        announce M_Pong;
			_SEND(payload, Pong, this);
			_SEND(payload, Pong, this);
	    }
        on Ping goto SendPong;
	}

    state SendPong {
	    entry (payload: machine) {
	        announce M_Pong;
			_SEND(payload, Pong, this);
			raise (Success);		 	  
	    }
        on Success goto End;
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
