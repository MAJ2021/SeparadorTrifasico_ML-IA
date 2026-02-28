model SeparadorOil_V48_38
  parameter Real V_sep   = 17.0;              // volumen separador [m3]
  parameter Real Qin_base = 450/86400;        // caudal entrada oil ~0.005208 m3/s
  parameter Real Cv = 0.0033;                 // coeficiente de válvula [m3/s]/√bar
  parameter Real P_sep = 3.5;                 // presión separador [bar]
  parameter Real P_linea = 1.0;               // presión línea salida [bar]

  Real V_oil(start=0.0);                      // arranque desde cero
  Real V_oil_pct;                             // nivel en %
  Real spOil_pct;                             // setpoint en %
  Real error;
  Real integralError(start=0);
  Real valveOpening;
  Real Qin, Qout;
  Real deltaP;

  parameter Real Kp = 0.02;                   // proporcional
  parameter Real Ki = 2e-4;                   // integral

  // Setpoint fijo en 54%
  Modelica.Blocks.Sources.Constant spOil(k=54);

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Nivel en porcentaje (limitado entre 0 y 100)
  V_oil_pct = noEvent(min(max((V_oil/V_sep)*100, 0), 100));

  // Setpoint externo
  spOil_pct = spOil.y;

  // Error y control PI
  error = spOil_pct - V_oil_pct;
  der(integralError) = error;

  // Apertura de válvula con saturación explícita (0–1)
  valveOpening = noEvent(min(max(Kp*error + Ki*integralError,0),1));

  // Diferencia de presión
  deltaP = noEvent(max(P_sep - P_linea, 0));

  // Caudal de salida con ecuación de válvula hidráulica
  Qout = noEvent(min(Cv * valveOpening * sqrt(deltaP), V_oil));

  // Entrada fija
  Qin = Qin_base;
end SeparadorOil_V48_38;
