model SeparadorOil_V46_7
  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_oil_dia = 440.0 "Producción oil m3/día (promedio)";
  parameter Real Qin_base = Qin_oil_dia/86400 "Caudal base m3/s";
  parameter Real Qout_max = 10*Qin_base "Capacidad máxima válvula m3/s";

  Real V_oil(start=0.54*V_sep);
  Real Qin, Qout;
  Real valveOpening;

  Real V_oil_pct;
  Real spOil_pct = 54;

  Modelica.Blocks.Continuous.PID pid(k=2.0, Ti=200, Td=0.1, y_start=0.5);

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Nivel en porcentaje
  V_oil_pct = (V_oil / V_sep) * 100;

  // Control PID en porcentaje
  pid.u = spOil_pct - V_oil_pct;
  valveOpening = min(max(pid.y, 0), 1);

  // Salida gobernada por válvula
  Qout = valveOpening * Qout_max;

  // Fases de operación
  if time < 1800 then
    Qin = Qin_base;
  elseif time < 3600 then
    Qin = 2.5*Qin_base;
  elseif time < 5400 then
    Qin = 0.2*Qin_base;
  else
    Qin = Qin_base;
  end if;

end SeparadorOil_V46_7;
