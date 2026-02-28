model SeparadorOil_V48_24
 parameter Real V_sep   = 17.0;              // volumen separador [m3]
  parameter Real Qin_base = 440/86400;        // caudal entrada ~0.0051 m3/s
  parameter Real Qout_max = 0.0047;           // drenaje máximo

  Real V_oil(start=0.0);                      // volumen de oil [m3]
  Real V_oil_pct;                             // nivel en %
  Real spOil_pct;                             // setpoint en %
  Real Qin, Qout;

  // Setpoint: 54% hasta 1800s, luego 90%
  Modelica.Blocks.Sources.Step stepSP(height=36, startTime=1800, offset=54);

  // Controlador PI estándar (usa k y T)
  Modelica.Blocks.Continuous.PI piCtrl(k=0.002, T=500);

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Nivel en porcentaje
  V_oil_pct = (V_oil/V_sep)*100;

  // Setpoint externo
  spOil_pct = stepSP.y;

  // PI recibe el error
  piCtrl.u = spOil_pct - V_oil_pct;

  // Caudal de salida controlado por PI
  Qout = piCtrl.y * Qout_max;

  // Entrada fija
  Qin = Qin_base;



end SeparadorOil_V48_24;
