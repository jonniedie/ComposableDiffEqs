struct MyView
    viewer
    array
    function MyView(array)
        viewer = Dict(:a => @view array[1:end])
        return new(viewer, array)
    end
end
