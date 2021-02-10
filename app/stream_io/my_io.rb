class MyIO
  def initialize(st)
    @st = st
  end                                                                                                                   

  def <<(data)
    @st.write(data)
  end

  def close
    @st.close
  end
end
