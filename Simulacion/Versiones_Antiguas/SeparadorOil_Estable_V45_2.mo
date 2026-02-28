model SeparadorOil_Estable_V45_2
  inner Modelica.Fluid.System system;

  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_oil_base = 300/86400 "Caudal base de petróleo m3/s"; // reducido
  parameter Real tauRec = 400 "Constante de tiempo de recuperación";      // más rápida
  parameter Real Tdelay = 5 "Retardo dinámico de válvulas";

  Real V_oil(start=0, min=0);
  Real Qin_oil, Qout_oil;
  Real valveOilOut;

  Modelica.Blocks.Continuous.PID pidOilOut(k=0.05, Ti=2000, Td=0.1); // PID más agresivo
  Modelica.Blocks.Continuous.FirstOrder delayOilOut(T=Tdelay);

  Real V_oil_pct, spOil_pct;
  Real spDynamic;
  Real osc;

equation
  spDynamic = 0.54*V_sep;

  der(V_oil) = Qin_oil - Qout_oil - (V_oil - spDynamic)/tauRec;

  pidOilOut.u = (V_oil/V_sep*100) - (spDynamic/V_sep*100);
  delayOilOut.u = pidOilOut.y;
  valveOilOut = min(max(delayOilOut.y, 0), 1);

  Qin_oil = Qin_oil_base;

  osc = 0.01*sin(time/200);

  Qout_oil = valveOilOut * Qin_oil_base * (1 + osc);

  V_oil_pct = V_oil / V_sep * 100;
  spOil_pct = spDynamic / V_sep * 100;

end SeparadorOil_Estable_V45_2;
