require 'redparse'

class RedParse::Node
  def toplevel_ocelot_compile(env)
    return ocelot_compile(env)
  end

  def ocelot_compile_funcall(env, recv, name, *params)
    return env.scope {
      s = ''
      if recv then
        s << recv.ocelot_compile(env)
        s << "VALUE recv = result;\n"
      else
        s << "VALUE recv = self;\n"
      end
      s << %Q{ID name = rb_intern("#{name}");\n}
      argc = params.size
      s << "VALUE argv[#{argc}];\n"
      params.each_with_index { |param, idx|
        s << param.ocelot_compile(env)
        s << "argv[#{idx}] = result;\n"
      }
      s << %Q{result = rb_funcall2(recv, name, #{argc}, argv);\n}
      s
    }
  end
end

class RedParse::SequenceNode
  def toplevel_ocelot_compile(env)
    s = ''
    self.each do |child|
      s << child.ocelot_compile(env) << ";\n"
    end
    return s
  end
end

class RedParse::LiteralNode
  def ocelot_compile(env)
    return %Q{result = rb_eval_string("#{val}");\n}
  end
end

class RedParse::CallSiteNode
  def ocelot_compile(env)
    fail if block

    return self.ocelot_compile_funcall(
        env,
        receiver,
        name,
        *params)
  end
end

module RedParse::OpNode
  def ocelot_compile(env)
    return self.ocelot_compile_funcall(
        env,
        left,
        op,
        right)
  end
end

module Ocelot

class CompileEnvironment
  attr_reader :indent_level

  def indent_block(&block)
    t = yield
    t.gsub!(/^/, "  ")
    return t
  end

  def scope(&block)
    s = "{\n"
    s << indent_block(&block)
    s << "}\n"
    return s
  end
end

PROGRAM_TEMPLATE = <<END
#include <ruby.h>

VALUE run_program()
{
  VALUE result;
  VALUE self = rb_cObject; /* TODO: should be toplevel object */
%{statement_list}
  return result;
}

int main(int argc, char * argv[])
{
  char * dummy_argv[] = { argv[0], "-e", "" };
  RUBY_INIT_STACK;
  ruby_init();
  ruby_options(3, dummy_argv);
  ruby_script("ocelot");
  run_program();
  return 0;
}
END

class Compiler
  def compile(tree)
    env = Ocelot::CompileEnvironment.new
    statement_list = env.indent_block {
      tree.toplevel_ocelot_compile(env)
    }
    PROGRAM_TEMPLATE.sub("%{statement_list}", statement_list)
  end
end

end

if $0 == __FILE__ then
  s = "puts 42; puts 1+1"
  # s = "puts 42"
  p = RedParse.new(s)
  tree = p.parse()

  require 'pp'
  # pp tree

  compiler = Ocelot::Compiler.new
  output = compiler.compile(tree)
  puts output
end

