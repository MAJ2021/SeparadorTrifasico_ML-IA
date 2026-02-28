model SeparadorOil_V46_3
  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_oil_dia = 440.0 "Producción oil m3/día (promedio)";
  parameter Real Qin_base = Qin_oil_dia/86400 "Caudal base m3/s";
  parameter Real Qout_max = 10*Qin_base "Capacidad máxima válvula m3/s";

  Real V_oil(start=0.54*V_sep, min=0, max=V_sep);
  Real Qin, Qout;
  Real valveOpening;

  Modelica.Blocks.Continuous.PID pid(k=1.0, Ti=300, Td=0.1);

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Control PID
  pid.u = (0.54*V_sep - V_oil);
  valveOpening = min(max(pid.y, 0), 1);

  // Salida limitada por volumen disponible
  Qout = min(valveOpening * Qout_max, V_oil);

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

end SeparadorOil_V46_3;
