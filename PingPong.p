event OTPSecretMsg assert 1: (machine, int);
event OTPSecretReceived;
event OTPCode assert 1: int;
event OTPCodeValidated;
event Success;

machine BANK_SERVER 
{
    var clientOtpGenerator: machine;

    // This is the entry point.
    start state Init {
        entry (payload:any) {
          clientOtpGenerator = payload as machine;
          raise (Success);   	   
        }
        on Success goto GenerateOTPSecret;
    }

    state GenerateOTPSecret {
        entry {
			// generate OTP secret 
			// var secret: StringType;
			send clientOtpGenerator, OTPSecretMsg, (this, 3);
	    }
        on OTPSecretReceived goto WaitOTPCode;
     }

     state WaitOTPCode {
        on OTPCode goto ValidateOTPCode;
     }

	 state ValidateOTPCode {
        entry (payload: int) {
          send clientOtpGenerator, OTPCodeValidated;
          raise (Success);   	   
        }
		on Success goto Done;
     }

     state Done {}
}

machine CLIENT_OTP_GENERATOR
{
	var bankServer : machine;

    start state Init {
        on OTPSecretMsg goto WaitOTPSecret;
    }

    state WaitOTPSecret {
	    entry (payload: (machine, int)) {
	        bankServer = payload.0;
			send bankServer, OTPSecretReceived;
			raise (Success);	 	  
	    }
        on Success goto GenerateOTPCode;
    }

	state GenerateOTPCode {
	    entry {
			send bankServer, OTPCode, 7;
	    }
        on OTPCodeValidated goto End;
    }
	
	state End {
		entry {
			raise(halt);
		}
	}
}

spec M observes Success {
    start state initialState {

    }
}

fun _CREATEMACHINE(cner: machine, typeOfMachine: int, param : any, newMachine: machine) : machine
{
	if(typeOfMachine == 1)
	{
		newMachine = new BANK_SERVER(param);
	}
	else if(typeOfMachine == 2)
	{
		newMachine = new CLIENT_OTP_GENERATOR();
	}
	else
	{
		assert(false);
	}
	return newMachine;
}

machine IntializerMachine
{
	var container : machine;
    var clientMachine: machine;

    start state Init {
	    entry {
			container = _CREATECONTAINER();
			clientMachine = _CREATEMACHINE(container, 2, null, null as machine);
			container = _CREATECONTAINER();
			_CREATEMACHINE(container, 1, clientMachine, null as machine); //Create bank server
	    }
	}
}
