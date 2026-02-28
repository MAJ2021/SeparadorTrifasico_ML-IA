model SeparadorOil_V47_1
  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_base = 440/86400 "Caudal base m3/s";
  parameter Real Qout_max = 10*Qin_base;

  Real V_oil(start=0.54*V_sep);
  Real Qin, Qout;
  Real valveOpening;
  Real V_oil_pct;
  Real spOil_pct = 54;

  // PID con ganancia fuerte y salida inicial
  Modelica.Blocks.Continuous.PID pid(k=10.0, Ti=50, Td=0.1, y_start=0.5);

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

  // Perturbaciones en la entrada
  if time < 1800 then
    Qin = Qin_base;          // meseta inicial
  elseif time < 3600 then
    Qin = 2.5*Qin_base;      // exceso
  elseif time < 5400 then
    Qin = 0.2*Qin_base;      // vaciado
  else
    Qin = Qin_base;          // recuperación
  end if;

end SeparadorOil_V47_1;
