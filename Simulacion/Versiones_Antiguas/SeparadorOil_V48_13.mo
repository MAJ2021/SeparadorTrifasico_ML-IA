model SeparadorOil_V48_13
  parameter Real V_sep   = 17.0 "Volumen máximo del separador m3";
  parameter Real Qin_base = 440/86400 "Caudal base m3/s";
  parameter Real Qout_max = 0.0093;   // calibrado para equilibrio en 54%

  Real V_oil(start=0.0);
  Real Qin, Qout;
  Real valveOpening;
  Real V_oil_pct;
  Real spOil_pct = 54;
  Real error;
  Real integralError(start=0);

  parameter Real Kp = 0.005;
  parameter Real Ki = 1e-4;

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

  // Restricciones físicas
  when V_oil < 0 then
    reinit(V_oil, 0);
  end when;

  when V_oil > V_sep then
    reinit(V_oil, V_sep);
  end when;

end SeparadorOil_V48_13;
