within ;
package AbsorptionChiller
  "Single-effect NH3-H2O absorption chiller: complete steady-state cycle with graphical components (TILMedia 2024.1)"

  // =====================================================================
  //  COMPLETE CYCLE  (open this model and simulate it)
  // =====================================================================
  model Cycle "Single-effect NH3-H2O absorption chiller - complete cycle (states 1-8)"
    import SI = Modelica.Units.SI;

    // -------------------- Inputs (same as the EES / AbsorptionCycle_001 model) --------------------
    parameter Boolean xiIsWater = true
      "true: TILMedia xi[1] is the water mass fraction (set false if X looks inverted)";
    parameter SI.Temperature T_amb = 273.15 + 25 "Ambient temperature";
    parameter SI.Temperature T_C   = 273.15 + 5  "Evaporator temperature";
    parameter SI.Temperature T_gen = 273.15 + 90 "Generator temperature";
    parameter SI.Temperature T_abs = 273.15 + 32 "Absorber temperature";
    parameter SI.AbsolutePressure P_gen = 1.6e6 "Generator (high-side) pressure";
    parameter SI.AbsolutePressure P_abs = 400e3 "Absorber (low-side) pressure";
    parameter SI.TemperatureDifference DT_cond = 4 "Condenser approach temperature";
    parameter SI.TemperatureDifference DT_evap = 3 "Evaporator approach temperature";
    parameter Real eta_p = 0.62 "Solution pump efficiency";
    parameter SI.MassFlowRate m_dot_r = 0.05 "Refrigerant mass flow rate";

    // -------------------- Components --------------------
    AbsorptionChiller.Components.ThermalCompressor thermalCompressor(
      xiIsWater=xiIsWater,
      T_gen=T_gen,
      T_abs=T_abs,
      P_gen=P_gen,
      P_abs=P_abs,
      eta_p=eta_p)
      annotation (Placement(transformation(extent={{60,-40},{140,40}})));
    AbsorptionChiller.Components.Condenser condenser(
      xiIsWater=xiIsWater,
      T_out=T_amb + DT_cond)
      annotation (Placement(transformation(extent={{20,60},{-20,100}})));
    AbsorptionChiller.Components.ExpansionValve valve(
      xiIsWater=xiIsWater,
      m_flow_set=m_dot_r)
      annotation (Placement(transformation(extent={{-20,-20},{20,20}},
            rotation=270, origin={-80,0})));
    AbsorptionChiller.Components.Evaporator evaporator(
      xiIsWater=xiIsWater,
      T_out=T_C - DT_evap)
      annotation (Placement(transformation(extent={{-20,-100},{20,-60}})));

    // -------------------- State table (same numbering as the EES model) --------------------
    SI.Temperature T[8] "State temperatures";
    SI.AbsolutePressure P[8] "State pressures";
    SI.SpecificEnthalpy h[8] "State specific enthalpies";
    Real X[8](each min=0, each max=1) "State ammonia mass fractions";
    Real Qu[8] "State vapor qualities";

    // -------------------- Results --------------------
    Real Q_gen_kW(unit="kW")  = thermalCompressor.Q_flow_gen / 1e3 "Generator heat input";
    Real Q_evap_kW(unit="kW") = evaporator.Q_flow / 1e3 "Cooling capacity";
    Real Q_cond_kW(unit="kW") = condenser.Q_flow / 1e3 "Condenser heat rejection";
    Real Q_abs_kW(unit="kW")  = thermalCompressor.Q_flow_abs / 1e3 "Absorber heat rejection";
    Real W_pump_kW(unit="kW") = thermalCompressor.P_pump / 1e3 "Solution pump power";
    Real COP = evaporator.Q_flow / thermalCompressor.Q_flow_gen "Coefficient of performance";
    Real balance_W(unit="W") = thermalCompressor.Q_flow_gen + evaporator.Q_flow
      + thermalCompressor.P_pump - condenser.Q_flow - thermalCompressor.Q_flow_abs
      "Overall energy balance residual (should be ~0)";

    // -------------------- Diagram displays (values appear after simulation) --------------------
    Modelica.Blocks.Interaction.Show.RealValue dispQgen(use_numberPort=false,
      number=Q_gen_kW, significantDigits=3)
      annotation (Placement(transformation(extent={{183,76},{243,116}})));
    Modelica.Blocks.Interaction.Show.RealValue dispQevap(use_numberPort=false,
      number=Q_evap_kW, significantDigits=3)
      annotation (Placement(transformation(extent={{183,48},{243,88}})));
    Modelica.Blocks.Interaction.Show.RealValue dispQcond(use_numberPort=false,
      number=Q_cond_kW, significantDigits=3)
      annotation (Placement(transformation(extent={{183,20},{243,60}})));
    Modelica.Blocks.Interaction.Show.RealValue dispQabs(use_numberPort=false,
      number=Q_abs_kW, significantDigits=3)
      annotation (Placement(transformation(extent={{183,-8},{243,32}})));
    Modelica.Blocks.Interaction.Show.RealValue dispWpump(use_numberPort=false,
      number=W_pump_kW, significantDigits=3)
      annotation (Placement(transformation(extent={{183,-36},{243,4}})));
    Modelica.Blocks.Interaction.Show.RealValue dispCOP(use_numberPort=false,
      number=COP, significantDigits=3)
      annotation (Placement(transformation(extent={{183,-64},{243,-24}})));
    Modelica.Blocks.Interaction.Show.RealValue dispBalance(use_numberPort=false,
      number=balance_W, significantDigits=2)
      annotation (Placement(transformation(extent={{183,-92},{243,-52}})));

  equation
    // -------------------- Refrigerant loop --------------------
    connect(thermalCompressor.vaporOut, condenser.port_a)
      annotation (Line(points={{60,24},{40,24},{40,80},{20,80}},
          color={200,40,40}, thickness=0.5));
    connect(condenser.port_b, valve.port_a)
      annotation (Line(points={{-20,80},{-80,80},{-80,20}},
          color={200,40,40}, thickness=0.5));
    connect(valve.port_b, evaporator.port_a)
      annotation (Line(points={{-80,-20},{-80,-80},{-20,-80}},
          color={0,90,200}, thickness=0.5));
    connect(evaporator.port_b, thermalCompressor.vaporIn)
      annotation (Line(points={{20,-80},{40,-80},{40,-24},{60,-24}},
          color={0,90,200}, thickness=0.5));

    // -------------------- State table --------------------
    // 1: valve outlet / evaporator inlet
    T[1] = valve.T_out;              P[1] = valve.port_b.p;
    h[1] = valve.port_b.h_outflow;   X[1] = valve.port_b.X_outflow;   Qu[1] = valve.Qu_out;
    // 2: evaporator outlet / absorber inlet
    T[2] = evaporator.T_out;         P[2] = evaporator.port_b.p;
    h[2] = evaporator.port_b.h_outflow; X[2] = evaporator.port_b.X_outflow; Qu[2] = evaporator.Qu_out;
    // 3: generator vapor outlet / condenser inlet
    T[3] = thermalCompressor.T_gen;  P[3] = thermalCompressor.P_gen;
    h[3] = thermalCompressor.h3;     X[3] = thermalCompressor.X3;     Qu[3] = 1;
    // 4: condenser outlet / valve inlet
    T[4] = condenser.T_out;          P[4] = condenser.port_b.p;
    h[4] = condenser.port_b.h_outflow; X[4] = condenser.port_b.X_outflow; Qu[4] = condenser.Qu_out;
    // 5: absorber outlet / pump inlet
    T[5] = thermalCompressor.T_abs;  P[5] = thermalCompressor.P_abs;
    h[5] = thermalCompressor.h5;     X[5] = thermalCompressor.X5;     Qu[5] = 0;
    // 6: pump outlet / generator inlet
    T[6] = thermalCompressor.T6;     P[6] = thermalCompressor.P_gen;
    h[6] = thermalCompressor.h6;     X[6] = thermalCompressor.X5;     Qu[6] = thermalCompressor.Qu6;
    // 7: generator liquid outlet / solution valve inlet
    T[7] = thermalCompressor.T_gen;  P[7] = thermalCompressor.P_gen;
    h[7] = thermalCompressor.h7;     X[7] = thermalCompressor.X7;     Qu[7] = 0;
    // 8: solution valve outlet / absorber inlet
    T[8] = thermalCompressor.T8;     P[8] = thermalCompressor.P_abs;
    h[8] = thermalCompressor.h8;     X[8] = thermalCompressor.X7;     Qu[8] = thermalCompressor.Qu8;

    annotation (
      experiment(StopTime=1),
      Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-170,-150},{255,150}}),
        graphics={
          // pressure zones
          Rectangle(extent={{-165,0},{170,128}}, pattern=LinePattern.None,
            fillColor={255,243,238}, fillPattern=FillPattern.Solid),
          Rectangle(extent={{-165,-128},{170,0}}, pattern=LinePattern.None,
            fillColor={236,244,255}, fillPattern=FillPattern.Solid),
          Line(points={{-165,0},{170,0}}, color={150,150,150}, pattern=LinePattern.Dash),
          Text(extent={{-160,112},{-50,122}}, textColor={170,40,40},
            horizontalAlignment=TextAlignment.Left, textString="HIGH PRESSURE  (P_gen)"),
          Text(extent={{-160,-122},{-50,-112}}, textColor={20,60,150},
            horizontalAlignment=TextAlignment.Left, textString="LOW PRESSURE  (P_abs)"),
          // title
          Text(extent={{-165,132},{170,146}}, textColor={0,0,0},
            textString="Single-effect NH3-H2O absorption chiller (steady state)"),
          // heat flows at condenser and evaporator
          Line(points={{0,106},{0,124}}, color={200,60,0}, thickness=0.5,
            arrow={Arrow.None,Arrow.Filled}, arrowSize=5),
          Text(extent={{4,112},{44,122}}, textColor={200,60,0},
            horizontalAlignment=TextAlignment.Left, textString="Q_cond"),
          Line(points={{0,-124},{0,-106}}, color={0,90,200}, thickness=0.5,
            arrow={Arrow.None,Arrow.Filled}, arrowSize=5),
          Text(extent={{4,-122},{44,-112}}, textColor={0,90,200},
            horizontalAlignment=TextAlignment.Left, textString="Q_evap"),
          // output labels on the thermal compressor
          Text(extent={{150,20},{175,28}}, textColor={170,40,40},
            horizontalAlignment=TextAlignment.Left, textString="Q_gen"),
          Text(extent={{150,-4},{175,4}}, textColor={80,80,80},
            horizontalAlignment=TextAlignment.Left, textString="W_pump"),
          Text(extent={{150,-28},{175,-20}}, textColor={20,60,150},
            horizontalAlignment=TextAlignment.Left, textString="Q_abs"),
          // state labels 1-4 on the refrigerant loop
          Ellipse(extent={{-93,-55},{-83,-45}}, lineColor={0,0,0},
            fillColor={255,255,255}, fillPattern=FillPattern.Solid),
          Text(extent={{-93,-55},{-83,-45}}, textColor={0,0,0}, textString="1"),
          Ellipse(extent={{28,-57},{38,-47}}, lineColor={0,0,0},
            fillColor={255,255,255}, fillPattern=FillPattern.Solid),
          Text(extent={{28,-57},{38,-47}}, textColor={0,0,0}, textString="2"),
          Ellipse(extent={{28,47},{38,57}}, lineColor={0,0,0},
            fillColor={255,255,255}, fillPattern=FillPattern.Solid),
          Text(extent={{28,47},{38,57}}, textColor={0,0,0}, textString="3"),
          Ellipse(extent={{-55,82},{-45,92}}, lineColor={0,0,0},
            fillColor={255,255,255}, fillPattern=FillPattern.Solid),
          Text(extent={{-55,82},{-45,92}}, textColor={0,0,0}, textString="4"),
          // results panel
          Rectangle(extent={{176,-96},{252,128}}, lineColor={120,120,120},
            fillColor={255,255,255}, fillPattern=FillPattern.Solid, radius=3),
          Text(extent={{178,114},{250,124}}, textColor={0,0,0},
            textString="Results (after simulation)")}),
      Icon(coordinateSystem(preserveAspectRatio=false), graphics={
          Rectangle(extent={{-100,100},{100,-100}}, lineColor={95,95,95},
            fillColor={255,255,255}, fillPattern=FillPattern.Solid, radius=6),
          Rectangle(extent={{-100,100},{100,0}}, pattern=LinePattern.None,
            fillColor={255,225,215}, fillPattern=FillPattern.Solid),
          Rectangle(extent={{-100,0},{100,-100}}, pattern=LinePattern.None,
            fillColor={215,235,255}, fillPattern=FillPattern.Solid),
          Text(extent={{-90,40},{90,-40}}, textColor={0,0,0}, textString="NH3-H2O"),
          Text(extent={{-150,145},{150,108}}, textColor={0,0,255}, textString="%name")}),
      Documentation(info="<html>
<p>Complete single-effect NH3-H2O absorption chiller built from connectable
components. Inputs and state numbering match the EES / AbsorptionCycle_001 model,
so the state arrays T, P, h, X, Qu and the COP can be compared directly.</p>
<table border=\"1\" cellpadding=\"3\">
<tr><th>State</th><th>Location</th></tr>
<tr><td>1</td><td>Refrigerant valve outlet / evaporator inlet</td></tr>
<tr><td>2</td><td>Evaporator outlet / absorber inlet</td></tr>
<tr><td>3</td><td>Generator vapor outlet / condenser inlet</td></tr>
<tr><td>4</td><td>Condenser outlet / refrigerant valve inlet</td></tr>
<tr><td>5</td><td>Absorber outlet / solution pump inlet</td></tr>
<tr><td>6</td><td>Solution pump outlet / generator inlet</td></tr>
<tr><td>7</td><td>Generator liquid outlet / solution valve inlet</td></tr>
<tr><td>8</td><td>Solution valve outlet / absorber inlet</td></tr>
</table>
<p>Who sets what in the loop: the thermal compressor fixes both pressures,
the refrigerant expansion valve fixes the refrigerant mass flow, and the
condenser and evaporator pass pressure and flow through. This keeps every
component locally balanced.</p>
<p>After simulating, switch to the diagram layer in the Simulation tab to see
the results panel filled in.</p>
</html>"));
  end Cycle;

  // =====================================================================
  //  Interfaces
  // =====================================================================
  package Interfaces "Connectors and partial models"

    partial connector FluidPort "Steady-state NH3-H2O stream connector"
      Modelica.Units.SI.AbsolutePressure p "Pressure";
      flow Modelica.Units.SI.MassFlowRate m_flow
        "Mass flow rate INTO the component (positive = entering)";
      stream Modelica.Units.SI.SpecificEnthalpy h_outflow
        "Specific enthalpy of the fluid if it leaves through this port";
      stream Real X_outflow(min=0, max=1)
        "Ammonia mass fraction of the fluid if it leaves through this port";
    end FluidPort;

    connector FluidPort_a "Fluid inlet (filled circle)"
      extends FluidPort;
      annotation (Icon(graphics={Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,90,180},
              fillColor={0,90,180},
              fillPattern=FillPattern.Solid)}));
    end FluidPort_a;

    connector FluidPort_b "Fluid outlet (hollow circle)"
      extends FluidPort;
      annotation (Icon(graphics={Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,90,180},
              lineThickness=0.5,
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid)}));
    end FluidPort_b;

    partial model PartialNH3H2O "Common fluid definition for all components"
      replaceable parameter TILMedia.VLEFluidTypes.TILMedia_WaterAmmonia_nc2 vleFluidType
        constrainedby TILMedia.VLEFluidTypes.BaseVLEFluid
        "NH3-H2O working fluid"
        annotation (choicesAllMatching=true);
      parameter Boolean xiIsWater = true
        "true: TILMedia xi[1] is the water mass fraction (xi = 1 - X_NH3)";
    end PartialNH3H2O;

    partial model PartialTwoPort "Two-port flow-through component"
      extends PartialNH3H2O;
      FluidPort_a port_a "Inlet"
        annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
      FluidPort_b port_b "Outlet"
        annotation (Placement(transformation(extent={{90,-10},{110,10}})));
      Modelica.Units.SI.SpecificEnthalpy h_in = inStream(port_a.h_outflow)
        "Inlet enthalpy";
      Real X_in = inStream(port_a.X_outflow) "Inlet ammonia mass fraction";
      Modelica.Units.SI.MassFlowRate m_flow = port_a.m_flow "Mass flow rate";
    equation
      // Steady-state mass and species balance (composition passes through)
      port_a.m_flow + port_b.m_flow = 0;
      port_b.X_outflow = X_in;
      // Reverse-direction stream values (not used at the design point)
      port_a.h_outflow = inStream(port_b.h_outflow);
      port_a.X_outflow = inStream(port_b.X_outflow);
    end PartialTwoPort;
  end Interfaces;

  // =====================================================================
  //  Functions
  // =====================================================================
  package Functions "Helper functions"
    function xiOf "TILMedia composition vector from ammonia mass fraction"
      input Real X "Ammonia mass fraction";
      input Boolean xiIsWater = true "true: xi[1] is water mass fraction";
      output Real xi[1] "TILMedia composition vector";
    algorithm
      xi := {if xiIsWater then 1 - X else X};
      annotation (Inline=true);
    end xiOf;
  end Functions;

  // =====================================================================
  //  Components
  // =====================================================================
  package Components "Cycle components"

    model ThermalCompressor
      "Generator + absorber + solution pump + solution valve (states 5-8)"
      extends AbsorptionChiller.Interfaces.PartialNH3H2O;
      import SI = Modelica.Units.SI;
      import AbsorptionChiller.Functions.xiOf;

      // -------------------- Parameters --------------------
      parameter SI.Temperature T_gen = 273.15 + 90 "Generator temperature";
      parameter SI.Temperature T_abs = 273.15 + 32 "Absorber temperature";
      parameter SI.AbsolutePressure P_gen = 1.6e6 "Generator (high-side) pressure";
      parameter SI.AbsolutePressure P_abs = 400e3 "Absorber (low-side) pressure";
      parameter Real eta_p = 0.62 "Solution pump efficiency";

      parameter Real X3_start = 0.97 "Start: generator vapor NH3 fraction";
      parameter Real X5_start = 0.47 "Start: strong solution NH3 fraction";
      parameter Real X7_start = 0.38 "Start: weak solution NH3 fraction";

      // -------------------- Ports --------------------
      AbsorptionChiller.Interfaces.FluidPort_a vaporIn
        "Refrigerant from evaporator into absorber (state 2)"
        annotation (Placement(transformation(extent={{-110,-70},{-90,-50}})));
      AbsorptionChiller.Interfaces.FluidPort_b vaporOut
        "Refrigerant vapor from generator to condenser (state 3)"
        annotation (Placement(transformation(extent={{-110,50},{-90,70}})));

      Modelica.Blocks.Interfaces.RealOutput Q_flow_gen(unit="W", start=8e4)
        "Generator heat input"
        annotation (Placement(transformation(extent={{100,50},{120,70}})));
      Modelica.Blocks.Interfaces.RealOutput P_pump(unit="W") "Solution pump power"
        annotation (Placement(transformation(extent={{100,-10},{120,10}})));
      Modelica.Blocks.Interfaces.RealOutput Q_flow_abs(unit="W")
        "Absorber heat rejection"
        annotation (Placement(transformation(extent={{100,-70},{120,-50}})));

      // -------------------- Internal states --------------------
      SI.SpecificEnthalpy h2 "Inlet enthalpy (state 2)";
      Real X2 "Inlet NH3 fraction (state 2)";
      SI.SpecificEnthalpy h3 "State 3 enthalpy (saturated vapor)";
      Real X3(start=X3_start, min=0, max=1) "State 3 NH3 fraction";
      SI.SpecificEnthalpy h5 "State 5 enthalpy (saturated strong solution)";
      Real X5(start=X5_start, min=0, max=1) "State 5 NH3 fraction";
      SI.Density rho5 "State 5 density";
      SI.SpecificEnthalpy h6 "State 6 enthalpy (pump outlet)";
      SI.Temperature T6 "State 6 temperature";
      Real Qu6 "State 6 vapor quality";
      SI.SpecificEnthalpy h7 "State 7 enthalpy (saturated weak solution)";
      Real X7(start=X7_start, min=0, max=1) "State 7 NH3 fraction";
      SI.SpecificEnthalpy h8 "State 8 enthalpy (solution valve outlet)";
      SI.Temperature T8 "State 8 temperature";
      Real Qu8 "State 8 vapor quality";

      // -------------------- Flows --------------------
      SI.MassFlowRate m_dot_r_in "Refrigerant entering absorber";
      SI.MassFlowRate m_dot_r_out "Refrigerant leaving generator";
      SI.MassFlowRate m_dot_abs(start=0.35) "Strong solution, absorber -> generator";
      SI.MassFlowRate m_dot_gen(start=0.3) "Weak solution, generator -> absorber";
      Real f = m_dot_abs / max(m_dot_r_out, 1e-8) "Circulation ratio";

    equation
      // ===================== Port boundary conditions =====================
      // This component fixes both cycle pressures. The loop mass flow is set elsewhere
      // (by the refrigerant expansion valve), so the component stays locally balanced.
      vaporOut.p = P_gen;
      vaporIn.p  = P_abs;
      m_dot_r_out = -vaporOut.m_flow;
      m_dot_r_in  =  vaporIn.m_flow;

      h2 = inStream(vaporIn.h_outflow);
      X2 = inStream(vaporIn.X_outflow);

      vaporOut.h_outflow = h3;
      vaporOut.X_outflow = X3;
      vaporIn.h_outflow  = h5;         // only used if flow reverses
      vaporIn.X_outflow  = X5;

      // ===================== State 3 (dew point at P_gen, T_gen) =====================
      T_gen = TILMedia.VLEFluidFunctions.dewTemperature_pxi(vleFluidType, P_gen, xiOf(X3, xiIsWater));
      h3    = TILMedia.VLEFluidFunctions.dewSpecificEnthalpy_pxi(vleFluidType, P_gen, xiOf(X3, xiIsWater));

      // ===================== State 5 (bubble point at P_abs, T_abs) =====================
      T_abs = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, P_abs, xiOf(X5, xiIsWater));
      h5    = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(vleFluidType, P_abs, xiOf(X5, xiIsWater));
      rho5  = TILMedia.VLEFluidFunctions.bubbleDensity_pxi(vleFluidType, P_abs, xiOf(X5, xiIsWater));

      // ===================== State 6 (pump outlet) =====================
      h6  = h5 + (P_gen - P_abs) / (rho5 * eta_p);
      T6  = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, P_gen, h6, xiOf(X5, xiIsWater));
      Qu6 = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, P_gen, h6, xiOf(X5, xiIsWater));

      // ===================== State 7 (bubble point at P_gen, T_gen) =====================
      T_gen = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, P_gen, xiOf(X7, xiIsWater));
      h7    = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(vleFluidType, P_gen, xiOf(X7, xiIsWater));

      // ===================== State 8 (solution valve, isenthalpic) =====================
      h8  = h7;
      T8  = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, P_abs, h8, xiOf(X7, xiIsWater));
      Qu8 = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, P_abs, h8, xiOf(X7, xiIsWater));

      // ===================== Absorber balances =====================
      // Generator mass/species balances follow automatically at steady state.
      m_dot_r_in + m_dot_gen = m_dot_abs;
      m_dot_r_in * X2 + m_dot_gen * X7 = m_dot_abs * X5;
      m_dot_r_in * h2 + m_dot_gen * h8 = Q_flow_abs + m_dot_abs * h5;

      // ===================== Pump and generator energy =====================
      P_pump = m_dot_abs * (h6 - h5);
      m_dot_abs * h6 + Q_flow_gen = m_dot_r_out * h3 + m_dot_gen * h7;

      annotation (
        Icon(coordinateSystem(preserveAspectRatio=false), graphics={
            Rectangle(extent={{-100,100},{100,-100}}, lineColor={95,95,95},
              fillColor={250,250,250}, fillPattern=FillPattern.Solid, radius=6),
            // generator
            Rectangle(extent={{-60,92},{60,32}}, lineColor={170,40,40},
              fillColor={255,200,190}, fillPattern=FillPattern.Solid),
            Text(extent={{-58,74},{58,50}}, textColor={130,20,20}, textString="Generator"),
            // absorber
            Rectangle(extent={{-60,-32},{60,-92}}, lineColor={30,80,160},
              fillColor={190,215,255}, fillPattern=FillPattern.Solid),
            Text(extent={{-58,-50},{58,-74}}, textColor={20,50,130}, textString="Absorber"),
            // solution pump (strong solution up, right leg)
            Line(points={{40,-32},{40,32}}, color={0,0,0}),
            Ellipse(extent={{26,-14},{54,14}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Polygon(points={{32,-7},{48,-7},{40,9},{32,-7}}, lineColor={0,0,0},
              fillColor={0,0,0}, fillPattern=FillPattern.Solid),
            // solution valve (weak solution down, left leg)
            Line(points={{-40,32},{-40,-32}}, color={0,0,0}),
            Polygon(points={{-50,12},{-30,12},{-50,-12},{-30,-12},{-50,12}},
              lineColor={0,0,0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            // refrigerant lines to ports
            Line(points={{-100,60},{-60,60}}, color={200,40,40}, thickness=0.5),
            Line(points={{-100,-60},{-60,-60}}, color={0,90,200}, thickness=0.5),
            // heat / work arrows to the output connectors
            Line(points={{98,60},{62,60}}, color={200,60,0}, thickness=0.5,
              arrow={Arrow.None,Arrow.Filled}, arrowSize=8),
            Line(points={{98,0},{56,0}}, color={80,80,80},
              arrow={Arrow.None,Arrow.Filled}, arrowSize=8),
            Line(points={{62,-60},{98,-60}}, color={0,90,200}, thickness=0.5,
              arrow={Arrow.None,Arrow.Filled}, arrowSize=8),
            // internal state labels 5-8
            Ellipse(extent={{46,-30},{60,-16}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{46,-30},{60,-16}}, textColor={0,0,0}, textString="5"),
            Ellipse(extent={{46,16},{60,30}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{46,16},{60,30}}, textColor={0,0,0}, textString="6"),
            Ellipse(extent={{-62,16},{-48,30}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{-62,16},{-48,30}}, textColor={0,0,0}, textString="7"),
            Ellipse(extent={{-62,-30},{-48,-16}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{-62,-30},{-48,-16}}, textColor={0,0,0}, textString="8"),
            Text(extent={{-150,145},{150,108}}, textColor={0,0,255}, textString="%name")}),
        Documentation(info="<html>
<p>Combined generator / absorber (\"thermal compressor\") of a single-effect
NH3-H2O absorption cycle, steady state: absorber, solution pump, generator and
solution expansion valve (states 5-8).</p>
<ul>
<li><b>vaporIn</b> (state 2): refrigerant from the evaporator, enters the absorber.</li>
<li><b>vaporOut</b> (state 3): saturated vapor from the generator, to the condenser.</li>
<li>Outputs: generator heat input, solution pump power, absorber heat rejection (W).</li>
</ul>
<p>Fixes both pressures (P_gen at vaporOut, P_abs at vaporIn). The loop
mass flow must be set by another component (here the refrigerant expansion valve).</p>
</html>"));
    end ThermalCompressor;

    model Condenser "Refrigerant condenser with fixed outlet temperature"
      extends AbsorptionChiller.Interfaces.PartialTwoPort;
      import SI = Modelica.Units.SI;
      parameter SI.Temperature T_out = 273.15 + 29 "Outlet temperature (state 4)";
      Real Qu_out "Outlet vapor quality";
      Modelica.Blocks.Interfaces.RealOutput Q_flow(unit="W") "Heat rejected"
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
              rotation=90, origin={0,110})));
    equation
      port_b.p = port_a.p;
      port_b.h_outflow = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(
        vleFluidType, port_a.p, T_out, AbsorptionChiller.Functions.xiOf(X_in, xiIsWater));
      Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
        vleFluidType, port_a.p, port_b.h_outflow, AbsorptionChiller.Functions.xiOf(X_in, xiIsWater));
      Q_flow = m_flow * (h_in - port_b.h_outflow);
      annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
            Rectangle(extent={{-80,40},{80,-40}}, lineColor={170,40,40},
              fillColor={255,225,215}, fillPattern=FillPattern.Solid),
            Line(points={{-100,0},{-60,0},{-50,20},{-30,-20},{-10,20},{10,-20},
              {30,20},{50,-20},{60,0},{100,0}}, color={200,40,40}, thickness=0.5),
            Text(extent={{-80,-44},{80,-70}}, textColor={130,20,20}, textString="Condenser"),
            Text(extent={{-150,90},{150,56}}, textColor={0,0,255}, textString="%name")}));
    end Condenser;

    model ExpansionValve
      "Isenthalpic refrigerant expansion valve that sets the refrigerant mass flow"
      extends AbsorptionChiller.Interfaces.PartialTwoPort;
      import SI = Modelica.Units.SI;
      parameter SI.MassFlowRate m_flow_set = 0.05 "Refrigerant mass flow rate";
      SI.Temperature T_out "Outlet temperature";
      Real Qu_out "Outlet vapor quality";
    equation
      // Flow-controlled expansion device: sets the loop flow; the pressure drop
      // is whatever the thermal compressor's two pressure levels impose.
      port_a.m_flow = m_flow_set;
      port_b.h_outflow = h_in;
      T_out = TILMedia.VLEFluidFunctions.temperature_phxi(
        vleFluidType, port_b.p, h_in, AbsorptionChiller.Functions.xiOf(X_in, xiIsWater));
      Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
        vleFluidType, port_b.p, h_in, AbsorptionChiller.Functions.xiOf(X_in, xiIsWater));
      annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
            Polygon(points={{-80,40},{-80,-40},{0,0},{-80,40}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Polygon(points={{80,40},{80,-40},{0,0},{80,40}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Line(points={{-100,0},{-80,0}}, color={200,40,40}, thickness=0.5),
            Line(points={{80,0},{100,0}}, color={0,90,200}, thickness=0.5),
            Text(extent={{-150,90},{150,50}}, textColor={0,0,255}, textString="%name")}));
    end ExpansionValve;

    model Evaporator "Refrigerant evaporator with fixed outlet temperature"
      extends AbsorptionChiller.Interfaces.PartialTwoPort;
      import SI = Modelica.Units.SI;
      parameter SI.Temperature T_out = 273.15 + 2 "Outlet temperature (state 2)";
      Real Qu_out "Outlet vapor quality";
      Modelica.Blocks.Interfaces.RealOutput Q_flow(unit="W") "Cooling capacity"
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
              rotation=270, origin={0,-110})));
    equation
      port_b.p = port_a.p;
      port_b.h_outflow = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(
        vleFluidType, port_a.p, T_out, AbsorptionChiller.Functions.xiOf(X_in, xiIsWater));
      Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
        vleFluidType, port_a.p, port_b.h_outflow, AbsorptionChiller.Functions.xiOf(X_in, xiIsWater));
      Q_flow = m_flow * (port_b.h_outflow - h_in);
      annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
            Rectangle(extent={{-80,40},{80,-40}}, lineColor={30,80,160},
              fillColor={215,235,255}, fillPattern=FillPattern.Solid),
            Line(points={{-100,0},{-60,0},{-50,20},{-30,-20},{-10,20},{10,-20},
              {30,20},{50,-20},{60,0},{100,0}}, color={0,90,200}, thickness=0.5),
            Text(extent={{-80,70},{80,44}}, textColor={20,50,130}, textString="Evaporator"),
            Text(extent={{-150,-56},{150,-90}}, textColor={0,0,255}, textString="%name")}));
    end Evaporator;
  end Components;

  annotation (uses(TILMedia(version="2024.1"), Modelica(version="4.0.0")));
end AbsorptionChiller;
