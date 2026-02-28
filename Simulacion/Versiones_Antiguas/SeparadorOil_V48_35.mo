model SeparadorOil_V48_35
  parameter Real V_sep   = 17.0;              // volumen separador [m3]
  parameter Real Qin_base = 450/86400;        // caudal entrada oil ~0.0052 m3/s
  parameter Real Qout_max = 0.0053;           // drenaje máximo ≈ entrada

  Real V_oil(start=0.0);                      // volumen de oil [m3]
  Real V_oil_pct;                             // nivel en %
  Real spOil_pct;                             // setpoint en %
  Real error;
  Real integralError(start=0);
  Real valveOpening;
  Real Qin, Qout;

  parameter Real Kp = 0.004;                  // proporcional moderado
  parameter Real Ki = 4e-5;                   // integral ajustado

  // Setpoint fijo en 54%
  Modelica.Blocks.Sources.Constant spOil(k=54);

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Nivel en porcentaje (no negativo)
  V_oil_pct = noEvent(max((V_oil/V_sep)*100, 0));

  // Setpoint externo
  spOil_pct = spOil.y;

  // Error y control PI
  error = spOil_pct - V_oil_pct;
  der(integralError) = error;

  // Apertura de válvula con saturación explícita (0–1)
  valveOpening = noEvent(min(max(Kp*error + Ki*integralError,0),1));

  // Caudal de salida limitado
  Qout = noEvent(min(valveOpening * Qout_max, V_oil));

  // Entrada fija
  Qin = Qin_base;
end SeparadorOil_V48_35;
