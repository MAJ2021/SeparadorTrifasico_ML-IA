model SeparadorOil_V47_2
  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_base = 440/86400 "Caudal base m3/s";
  parameter Real Qout_max = 10*Qin_base;

  Real V_oil(start=0.54*V_sep);
  Real Qin, Qout;
  Real valveOpening;
  Real V_oil_pct;
  Real spOil_pct = 54;

  Modelica.Blocks.Math.Gain gain(k=0.1);

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Nivel en porcentaje
  V_oil_pct = (V_oil / V_sep) * 100;

  // Control proporcional
  gain.u = spOil_pct - V_oil_pct;
  valveOpening = noEvent(min(max(gain.y,0),1));

  // Salida gobernada por válvula
  Qout = valveOpening * Qout_max;

  // Entrada fija
  Qin = Qin_base;

end SeparadorOil_V47_2;
