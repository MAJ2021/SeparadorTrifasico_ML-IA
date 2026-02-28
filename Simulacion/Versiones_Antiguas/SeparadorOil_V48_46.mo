model SeparadorOil_V48_46
  parameter Real V_sep   = 17.0;
  parameter Real Qin_base = 450/86400;        // ~0.0052 m3/s
  parameter Real Cv = 0.0033;                 // coef válvula real
  parameter Real P_sep = 3.5;
  parameter Real P_linea = 1.0;

  Real V_oil(start=0.0);
  Real V_oil_pct;
  Real error;
  Real integralError(start=0);
  Real valveOpening;
  Real Qin, Qout;
  Real deltaP;

  parameter Real spOil_pct = 54;
  parameter Real Kp = 0.5;                    // más agresivo
  parameter Real Ki = 1e-3;                   // integral más rápida

equation
  der(V_oil) = Qin - Qout;

  V_oil_pct = noEvent(min(max((V_oil/V_sep)*100,0),100));

  error = spOil_pct - V_oil_pct;
  der(integralError) = error;

  valveOpening = noEvent(min(max(Kp*error + Ki*integralError,0),1));

  deltaP = noEvent(max(P_sep - P_linea,0));

  Qout = noEvent(min(Cv * valveOpening * sqrt(deltaP), V_oil));

  Qin = Qin_base;
end SeparadorOil_V48_46;
