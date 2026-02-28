model SeparadorOil_V48_16
  parameter Real V_sep   = 17.0;
  parameter Real Qin_base = 440/86400;
  parameter Real Qout_max = 0.0093;   // baseline calibrado

  Real V_oil(start=0.0);
  Real Qin, Qout;
  Real valveOpening;
  Real V_oil_pct;
  Real spOil_pct;
  Real error;
  Real integralError(start=0);

  parameter Real Kp = 0.005;
  parameter Real Ki = 1e-4;

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Nivel en porcentaje
  V_oil_pct = (V_oil / V_sep) * 100;

  // Secuencia de setpoints
  spOil_pct = if time < 1800 then 54 else 90;

  // Error
  error = spOil_pct - V_oil_pct;

  // Integral del error
  der(integralError) = error;

  // Control PI
  valveOpening = noEvent(min(max(Kp*error + Ki*integralError,0),1));

  // Caudal de salida dependiente del nivel
  Qout = valveOpening * Qout_max * (V_oil / V_sep);

  // Entrada fija
  Qin = Qin_base;

end SeparadorOil_V48_16;
