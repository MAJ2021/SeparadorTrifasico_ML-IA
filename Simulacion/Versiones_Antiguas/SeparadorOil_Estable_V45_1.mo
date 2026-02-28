model SeparadorOil_Estable_V45_1
  inner Modelica.Fluid.System system;

  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_oil_base = 400/86400 "Caudal base de petróleo m3/s";
  parameter Real tauRec = 700 "Constante de tiempo de recuperación";
  parameter Real Tdelay = 5 "Retardo dinámico de válvulas";

  // Estado del separador: arranca vacío
  Real V_oil(start=0, min=0);
  Real Qin_oil, Qout_oil;
  Real valveOilOut;

  // Control PID con retardo
  Modelica.Blocks.Continuous.PID pidOilOut(k=0.02, Ti=3000, Td=0.1);
  Modelica.Blocks.Continuous.FirstOrder delayOilOut(T=Tdelay);

  // Variables auxiliares
  Real V_oil_pct, spOil_pct;
  Real spDynamic;
  Real osc;

equation
  // Setpoint fijo en 54%
  spDynamic = 0.54*V_sep;

  // Balance dinámico
  der(V_oil) = Qin_oil - Qout_oil - (V_oil - spDynamic)/tauRec;

  // PID con retardo para salida
  pidOilOut.u = (V_oil/V_sep*100) - (spDynamic/V_sep*100);
  delayOilOut.u = pidOilOut.y;
  valveOilOut = min(max(delayOilOut.y, 0), 1);

  // Entrada constante
  Qin_oil = Qin_oil_base;

  // Oscilaciones suaves para realismo
  osc = 0.01*sin(time/200);

  // Salida regulada por PID
  Qout_oil = valveOilOut * Qin_oil_base * (1 + osc);

  // Variables en porcentaje
  V_oil_pct = V_oil / V_sep * 100;
  spOil_pct = spDynamic / V_sep * 100;

end SeparadorOil_Estable_V45_1;
