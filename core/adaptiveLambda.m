function Lamda = adaptiveLambda(gm)

Lamda = 2.5 * exp( -gm^2 / 72 );
return