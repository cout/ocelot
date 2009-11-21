require 'redparse'

class RedParse::LiteralNode
  def ocelot_compile(env)
    return %Q{rb_eval("#{val}")}
  end
end

module Ocelot

class CompileEnvironment
end

PROGRAM_TEMPLATE = <<END
#include <ruby.h>

VALUE run_program()
{
  %{statement_list}
}

int main(int argc, char * argv[])
{
  char dummy_argv[] = { };
  ruby_init();
  ruby_options(0, dummy_argv);
  run_program();
  return 0;
}
END

class Compiler
  def compile(tree)
    env = Ocelot::CompileEnvironment.new
    statement_list = tree.ocelot_compile(env)
  end
end

end

if $0 == __FILE__ then
  s = "42"
  p = RedParse.new(s)
  tree = p.parse()

  compiler = Ocelot::Compiler.new
  output = compiler.compile(tree)
  puts output
end

