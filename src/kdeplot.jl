const DEFAULT_RUG_SPACE = 0.05

"""
    kdeplot(x; kwargs...)
    kdeplot!(x; kwargs...)

Plot a 1D kernel density estimate (KDE) taking into account boundary conditions.

# Positional Arguments
- `x`: values

# Keyword Arguments
- `cumulative=false`: If `true`, plot the estimated cumulative distribution function
- `showrug=false`: If `true`, adds a rugplot
- `rugspace=$DEFAULT_RUG_SPACE`: control the `y` position of the rugplot. The larger this
    number the lower the rugplot
- `kwargs`: Additional attributes understood by Plots.jl. In particular, see keyword
    arguments for [`rugplot`](@ref).
"""
RecipesBase.@shorthands kdeplot

RecipesBase.@recipe function f(
    ::Type{Val{:kdeplot}},
    x,
    y,
    z;
    cumulative=false,
    showrug=false,
    rugspace=DEFAULT_RUG_SPACE,
)
    isrot = isrotated(plotattributes)
    kd = KernelDensity.kde(y; boundary=extrema(y))
    xnew = kd.x
    ynew = kd.density
    if cumulative
        ynew = cumsum(ynew)
        ynew ./= ynew[end]
    end
    if showrug
        ymax = maximum(ynew)
        if haskey(plotattributes, :rugsize)
            rugspace *= plotattributes[:rugsize] / DEFAULT_RUG_SIZE
        end
        RecipesBase.@series begin
            primary := false
            seriestype := :rugplot
            rugposition := -rugspace * ymax
            y := y
            ()
        end
    else # no need to set ylims if rug already widened axes for us
        if isrot
            xlims --> (0, Inf)
        else
            ylims --> (0, Inf)
        end
    end
    seriestype := :path
    if isrotated(plotattributes)
        xnew, ynew = ynew, xnew
    end
    x := xnew
    y := ynew
    return ()
end

"""
    kde2dplot(x, y; kwargs...)
    kde2dplot!(x, y; kwargs...)

Plot a 2D kernel density estimate (KDE) taking into account boundary conditions.

# Positional Arguments
- `x`: `x` coordinates of the values
- `y`: `y` coordinates of the values

# Keyword Arguments
- `cumulative=true`: If `true`, plot the 2D KDE using contours, otherwise plot a heatmap.
- `kwargs`: Additional attributes understood by Plots.jl.
"""
RecipesBase.@shorthands kde2dplot

RecipesBase.@recipe function f(::Type{Val{:kde2dplot}}, x, y, z; contour=true)
    kd = KernelDensity.kde((x, y); boundary=(extrema(x), extrema(y)))
    seriestype := contour ? :contour : :heatmap
    xnew, ynew = isrotated(plotattributes) ? (kd.x, kd.y) : (kd.y, kd.x)
    x := xnew
    y := ynew
    z := RecipesPipeline.Surface(kd.density')
    colorbar --> false
    return ()
end
