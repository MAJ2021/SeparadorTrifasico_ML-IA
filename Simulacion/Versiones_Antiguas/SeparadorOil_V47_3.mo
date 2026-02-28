model SeparadorOil_V47_3
  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_base = 440/86400 "Caudal base m3/s";
  parameter Real Qout_max = 10*Qin_base;

  Real V_oil(start=0.54*V_sep);
  Real Qin, Qout;
  Real valveOpening;
  Real V_oil_pct;
  Real spOil_pct = 54;
  Real error;

  // Bloques de control
  Modelica.Blocks.Math.Gain Kp(k=0.01);
  Modelica.Blocks.Continuous.Integrator Ki(k=0.0001);

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Nivel en porcentaje
  V_oil_pct = (V_oil / V_sep) * 100;

  // Error
  error = spOil_pct - V_oil_pct;

  // Parte proporcional
  Kp.u = error;

  // Parte integral
  Ki.u = error;

  // Apertura de válvula = P + I, limitada entre 0 y 1
  valveOpening = noEvent(min(max(Kp.y + Ki.y,0),1));

  // Caudal de salida gobernado por válvula
  Qout = valveOpening * Qout_max;

  // Entrada fija
  Qin = Qin_base;

end SeparadorOil_V47_3;
