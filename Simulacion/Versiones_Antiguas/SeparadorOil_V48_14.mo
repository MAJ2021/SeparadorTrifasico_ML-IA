model SeparadorOil_V48_14
  parameter Real V_sep   = 17.0;
  parameter Real Qin_base = 440/86400;
  parameter Real Qout_max = 0.0093;

  Real V_oil(start=9.0); // arranque en setpoint
  Real Qin, Qout;
  Real valveOpening;
  Real V_oil_pct;
  Real spOil_pct = 54;
  Real error;
  Real integralError(start=0);

  parameter Real Kp = 0.005;
  parameter Real Ki = 1e-4;

equation
  // Balance dinámico con límites físicos
  der(V_oil) = Qin - Qout;

  V_oil_pct = (V_oil / V_sep) * 100;
  error = spOil_pct - V_oil_pct;

  // Anti-windup: integrador solo si válvula no está saturada
  der(integralError) = if valveOpening > 0 and valveOpening < 1 then error else 0;

  valveOpening = noEvent(min(max(Kp*error + Ki*integralError,0),1));

  // Caudal de salida: cero si no hay líquido
  Qout = if V_oil <= 0 then 0 else valveOpening * Qout_max;

  Qin = Qin_base;

end SeparadorOil_V48_14;
