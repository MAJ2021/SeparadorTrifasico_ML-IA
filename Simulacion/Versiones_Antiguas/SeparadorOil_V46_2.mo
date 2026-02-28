model SeparadorOil_V46_2
  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_oil_dia = 440.0 "Producción oil m3/día (promedio)";
  parameter Real Qin_base = Qin_oil_dia/86400 "Caudal base m3/s";
  parameter Real Qout_max = 10*Qin_base "Capacidad máxima válvula m3/s";

  Real V_oil(start=0.1, min=0, max=V_sep);
  Real Qin, Qout;
  Real valveOpening;

  Modelica.Blocks.Continuous.PID pid(k=2.0, Ti=200, Td=0.1);

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Control PID
  pid.u = (0.54*V_sep - V_oil);
  valveOpening = min(max(pid.y, 0), 1);

  // Válvula gobernando salida
  Qout = valveOpening * Qout_max;

  // Fases de operación
  if time < 1800 then
    Qin = Qin_base;          // meseta inicial
  elseif time < 3600 then
    Qin = 2.5*Qin_base;      // exceso → sube a 90%
  elseif time < 5400 then
    Qin = 0.2*Qin_base;      // vaciado → baja a 20%
  else
    Qin = Qin_base;          // recuperación
  end if;

end SeparadorOil_V46_2;
