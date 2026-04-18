Bug in auth middleware. JWT not validated before request hits protected route. Verify secret key used to sign token matches key used to verify → mismatch causes auth failure.
