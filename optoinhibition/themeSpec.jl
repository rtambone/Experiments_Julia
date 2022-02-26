using Gadfly

#=
Gadfly.get_theme(::Val{:plotTheme}) = Theme(default_color= "red", 
                                            point_size= 0.9mm,
                                            line_width= 0.4mm,
                                            line_style= [:solid],
                                            panel_fill= "white",
                                            panel_stroke= nothing,      # border color of the main plot panel
                                            panel_line_width= 0.3mm,        # border line width for main plot panel 
                                            panel_opacity= 0.0,           # float in [0, 1]
                                            background_color= "white",
                                            grid_color= nothing)
=#

plotTheme = Theme(default_color= "red", 
                  point_size= 3mm,
                  line_width= 1mm,
                  line_style= [:solid],
                  panel_fill= "white",
                  panel_stroke= "black",      # border color of the main plot panel
                  panel_line_width= 0.3mm,        # border line width for main plot panel            # float in [0, 1]
                  background_color= "white",
                  grid_color= colorant"transparent",
                  key_title_font_size= 22pt,
                  key_label_font_size= 22pt,
                  minor_label_font_size= 20pt,
                  major_label_font_size= 22pt,
                  plot_padding= [2.0mm])
                  
Gadfly.push_theme(plotTheme)
println("Theme specification correctly imported and pushed")