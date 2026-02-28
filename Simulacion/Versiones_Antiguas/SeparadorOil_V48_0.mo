model SeparadorOil_V48_0
  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_base = 440/86400 "Caudal base m3/s";
  parameter Real Qout_max = 10*Qin_base;

  // Estado del separador
  Real V_oil(start=0.0);          // Arranca en 0 m3
  Real Qin, Qout;
  Real valveOpening;
  Real V_oil_pct;
  Real spOil_pct = 54;            // Setpoint en porcentaje
  Real error;
  Real integralError(start=0);

  // Ganancias del PI
  parameter Real Kp = 0.05;
  parameter Real Ki = 0.0005;

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Nivel en porcentaje
  V_oil_pct = (V_oil / V_sep) * 100;

  // Error
  error = spOil_pct - V_oil_pct;

  // Integral del error
  der(integralError) = error;

  // Control PI manual
  valveOpening = noEvent(min(max(Kp*error + Ki*integralError,0),1));

  // Caudal de salida gobernado por válvula
  Qout = valveOpening * Qout_max;

  // Entrada fija
  Qin = Qin_base;

end SeparadorOil_V48_0;
