model SeparadorOil_V48_29
  parameter Real V_sep   = 17.0;              // volumen separador [m3]
  parameter Real Qin_base = 440/86400;        // caudal entrada ~0.0051 m3/s
  parameter Real Qout_max = 0.0047;           // drenaje máximo

  Real V_oil(start=0.0);                      // volumen de oil [m3]
  Real V_oil_pct;                             // nivel en %
  Real spOil_pct;                             // setpoint en %
  Real error;
  Real integralError(start=0);
  Real valveOpening;
  Real Qin, Qout;

  parameter Real Kp = 0.002;
  parameter Real Ki = 2e-5;

  // Setpoint: 54% hasta 1800s, luego 90%
  Modelica.Blocks.Sources.Step stepSP(height=36, startTime=1800, offset=54);

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Nivel en porcentaje
  V_oil_pct = (V_oil/V_sep)*100;

  // Setpoint externo
  spOil_pct = stepSP.y;

  // Error y control PI
  error = spOil_pct - V_oil_pct;
  der(integralError) = error;

  // Apertura de válvula con saturación explícita (0–1)
  valveOpening = noEvent(min(max(Kp*error + Ki*integralError,0),1));

  // Caudal de salida
  Qout = valveOpening * Qout_max;

  // Entrada fija
  Qin = Qin_base;
end SeparadorOil_V48_29;
