if defined(windows):
  # リンカに対して、重複したシンボルを許容するように指示（力業ですが有効です）
  switch("passL", "-Wl,--allow-multiple-definition")
  
--define:release
--define:danger
--define:"blas=openblas"
--define:"lapack=openblas"
# --define:openmp