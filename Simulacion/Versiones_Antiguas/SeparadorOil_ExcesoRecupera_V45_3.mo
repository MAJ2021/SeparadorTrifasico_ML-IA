model SeparadorOil_ExcesoRecupera_V45_3
  inner Modelica.Fluid.System system;

  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_oil_base = 300/86400 "Caudal base de petróleo m3/s";
  parameter Real tauRec = 400 "Constante de tiempo de recuperación";
  parameter Real Tdelay = 5 "Retardo dinámico de válvulas";

  Real V_oil(start=0, min=0);
  Real Qin_oil, Qout_oil;
  Real valveOilOut;

  Modelica.Blocks.Continuous.PID pidOilOut(k=0.05, Ti=2000, Td=0.1);
  Modelica.Blocks.Continuous.FirstOrder delayOilOut(T=Tdelay);

  Real V_oil_pct, spOil_pct;
  Real spDynamic;
  Real osc;

equation
  // Setpoint fijo en 54%
  spDynamic = 0.54*V_sep;

  // Balance dinámico
  der(V_oil) = Qin_oil - Qout_oil - (V_oil - spDynamic)/tauRec;

  // PID con retardo
  pidOilOut.u = (V_oil/V_sep*100) - (spDynamic/V_sep*100);
  delayOilOut.u = pidOilOut.y;
  valveOilOut = min(max(delayOilOut.y, 0), 1);

  // Entrada y salida según fases
  if time < 1800 then
    // Meseta inicial en 54%
    Qin_oil = Qin_oil_base;
    Qout_oil = Qin_oil;
  elseif time >= 1800 and time < 3600 then
    // Perturbación exceso → sube a 90%
    Qin_oil = Qin_oil_base*2.5;
    Qout_oil = valveOilOut * Qin_oil_base;
  else
    // Recuperación y meseta en 54%
    Qin_oil = Qin_oil_base;
    Qout_oil = Qin_oil;
  end if;

  // Oscilaciones suaves
  osc = 0.01*sin(time/200);

  // Variables en porcentaje
  V_oil_pct = V_oil / V_sep * 100;
  spOil_pct = spDynamic / V_sep * 100;

end SeparadorOil_ExcesoRecupera_V45_3;
