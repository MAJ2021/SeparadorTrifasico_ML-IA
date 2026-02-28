model SeparadorOil_V48_1
  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_base = 440/86400 "Caudal base m3/s";
  parameter Real Qout_max = 100 * Qin_base;   // más capacidad de salida

  Real V_oil(start=0.0);
  Real Qin, Qout;
  Real valveOpening;
  Real V_oil_pct;
  Real spOil_pct = 54;
  Real error;
  Real integralError(start=0);

  parameter Real Kp = 0.02;
  parameter Real Ki = 0.0001;

equation
  // Balance dinámico con límite físico
  der(V_oil) = max(Qin - Qout, -V_oil);   // evita que se vuelva negativo

  // Nivel en porcentaje
  V_oil_pct = (V_oil / V_sep) * 100;

  // Error
  error = spOil_pct - V_oil_pct;

  // Integral del error con anti-windup
  der(integralError) = if valveOpening > 0 and valveOpening < 1 then error else 0;

  // Control PI manual
  valveOpening = noEvent(min(max(Kp*error + Ki*integralError,0),1));

  // Caudal de salida gobernado por válvula
  Qout = valveOpening * Qout_max;

  // Entrada fija
  Qin = Qin_base;

end SeparadorOil_V48_1;
