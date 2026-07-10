capture program drop test_pyado
program define test_pyado
    di as text "before python"

python:
print("hello from python")
end

    di as text "after python"
end
