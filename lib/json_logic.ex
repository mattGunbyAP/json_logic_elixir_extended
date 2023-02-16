defmodule JsonLogic do
  @moduledoc """
  An Elixir implementation of [JsonLogic](http://jsonlogic.com/).
  """

  @falsey [0, "", [], nil, false]

  @doc """
  Resolves the JsonLogic. It accepts logic and data arguments as a map, and
  returns the results as a map.

  ## Examples

  ```elixir
  JsonLogic.resolve(nil)
  #=> nil

  JsonLogic.resolve(%{})
  #=> %{}

  JsonLogic.resolve(%{"var" => "key"}, %{"key" => "value"})
  #=> "value"

  JsonLogic.resolve(%{"var" => "nested.key"}, %{"nested" => %{"key" => "value"}})
  #=> "value"

  JsonLogic.resolve(%{"var" => ["none", "default"]}, %{"key" => "value"})
  #=> "default"

  JsonLogic.resolve(%{"var" => 0}, ~w{a b})
  #=> "a"

  JsonLogic.resolve(%{"==" => [1, 1]})
  #=> true

  JsonLogic.resolve(%{"==" => [0, 1]})
  #=> false

  JsonLogic.resolve(%{"!=" => [1, 1]})
  #=> false

  JsonLogic.resolve(%{"!=" => [0, 1]})
  #=> true

  JsonLogic.resolve(%{"===" => [1, 1]})
  #=> true

  JsonLogic.resolve(%{"===" => [1, 1.0]})
  #=> false

  JsonLogic.resolve(%{"===" => [1, %{"var" => "key"}]}, %{"key" => 1})
  #=> true

  JsonLogic.resolve(%{"!==" => [1, 1.0]})
  #=> true

  JsonLogic.resolve(%{"!==" => [1, 1]})
  #=> false

  JsonLogic.resolve(%{"!" => true})
  #=> false

  JsonLogic.resolve(%{"!" => false})
  #=> true

  JsonLogic.resolve(%{"if" => [true, "yes", "no" ]})
  #=> "yes"

  JsonLogic.resolve(%{"if" => [false, "yes", "no" ]})
  #=> "no"

  JsonLogic.resolve(%{"if" => [false, "unexpected", false, "unexpected", "default" ]})
  #=> "default"

  JsonLogic.resolve(%{"or" => [false, nil, "truthy"]})
  #=> "truthy"

  JsonLogic.resolve(%{"or" => ["first", "truthy"]})
  #=> "first"

  JsonLogic.resolve(%{"and" => [false, "falsy"]})
  #=> false

  JsonLogic.resolve(%{"and" => [true, 1, "truthy"]})
  #=> "truthy"

  JsonLogic.resolve(%{"max" => [1,2,3]})
  #=> 3

  JsonLogic.resolve(%{"min" => [1,2,3]})
  #=> 1

  JsonLogic.resolve(%{"<" => [0, 1]})
  #=> true

  JsonLogic.resolve(%{"<" => [1, 0]})
  #=> false

  JsonLogic.resolve(%{"<" => [0, 1, 2]})
  #=> true

  JsonLogic.resolve(%{"<" => [0, 2, 1]})
  #=> false

  JsonLogic.resolve(%{">" => [1, 0]})
  #=> true

  JsonLogic.resolve(%{">" => [0, 1]})
  #=> false

  JsonLogic.resolve(%{">" => [2, 1, 0]})
  #=> true

  JsonLogic.resolve(%{">" => [2, 0, 1]})
  #=> false

  JsonLogic.resolve(%{"<=" => [1, 1]})
  #=> true

  JsonLogic.resolve(%{"<=" => [1, 0]})
  #=> false

  JsonLogic.resolve(%{"<=" => [1, 1, 2]})
  #=> true

  JsonLogic.resolve(%{"<=" => [1, 0, 2]})
  #=> false

  JsonLogic.resolve(%{">=" => [1, 1]})
  #=> true

  JsonLogic.resolve(%{">=" => [0, 1]})
  #=> false

  JsonLogic.resolve(%{">=" => [1, 1, 0]})
  #=> true

  JsonLogic.resolve(%{">=" => [0, 1, 2]})
  #=> false

  JsonLogic.resolve(%{"+" => [1,2,3]})
  #=> 6

  JsonLogic.resolve(%{"+" => [2]})
  #=> 2

  JsonLogic.resolve(%{"-" => [7,4]})
  #=> 3

  JsonLogic.resolve(%{"-" => [2]})
  #=> -2

  JsonLogic.resolve(%{"*" => [2,3,4]})
  #=> 24

  JsonLogic.resolve(%{"/" => [5,2]})
  #=> 2.5

  JsonLogic.resolve(%{"%" => [7, 3]})
  #=> 1

  JsonLogic.resolve(%{"map" => [[1,2,3,4,5], %{"*" => [%{"var" => ""}, 2]}]})
  #=> [2,4,6,8,10]

  JsonLogic.resolve(%{"filter" => [[1,2,3,4,5], %{">" => [%{"var" => ""}, 2]}]})
  #=> [3,4,5]

  JsonLogic.resolve(%{"reduce" => [[1,2,3,4,5], %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]}, 0]})
  #=> 15

  JsonLogic.resolve(%{"all" => [[1,2,3], %{">" => [%{"var" => ""}, 0]}]})
  #=> true

  JsonLogic.resolve(%{"all" => [[-1,2,3], %{">" => [%{"var" => ""}, 0]}]})
  #=> false

  JsonLogic.resolve(%{"none" => [[1,2,3], %{"<" => [%{"var" => ""}, 0 ]}]})
  #=> true

  JsonLogic.resolve(%{"none" => [[-1,2,3], %{"<" => [%{"var" => ""}, 0 ]}]})
  #=> false

  JsonLogic.resolve(%{"some" => [[-1,2,3], %{"<" => [%{"var" => ""}, 0 ]}]})
  #=> true

  JsonLogic.resolve(%{"some" => [[1,2,3], %{"<" => [%{"var" => ""}, 0 ]}]})
  #=> false

  JsonLogic.resolve(%{"in" => ["sub", "substring"]})
  #=> true

  JsonLogic.resolve(%{"in" => ["na", "substring"]})
  #=> false

  JsonLogic.resolve(%{"in" => ["a", ["a", "b", "c"]]})
  #=> true

  JsonLogic.resolve(%{"in" => ["z", ["a", "b", "c"]]})
  #=> false

  JsonLogic.resolve(%{"cat" => ["a", "b", "c"]})
  #=> "abc"

  JsonLogic.resolve(%{"log" => "string"})
  #=> "string"
  ```
  """
  @spec resolve(map()) :: term()
  @spec resolve(map(), map() | nil) :: term()
  def resolve(logic, data \\ nil)

  def resolve(logic, data) when map_size(logic) == 1 do
    operation_name =
      logic
      |> Map.keys()
      |> List.first()

    values =
      logic
      |> Map.values()
      |> List.first()

    operation(operation_name, values, data)
  end

  def resolve(logic, data) when is_list(logic) do
    operation("merge", logic, data)
  end

  def resolve(logic, _) when map_size(logic) > 1,
    do: raise(ArgumentError, "Invalid logic provided `#{inspect(logic)}`")

  def resolve(logic, _), do: logic

  defp operation("and", [first], data), do: resolve(first, data)

  defp operation("and", [first | rest], data) do
    case resolve(first, data) do
      resolved when resolved in @falsey ->
        resolved

      _resolved ->
        operation("and", rest, data)
    end
  end

  defp operation("or", [first], data), do: resolve(first, data)

  defp operation("or", [first | others], data) do
    case resolve(first, data) do
      resolved when resolved in @falsey ->
        operation("or", others, data)

      resolved ->
        resolved
    end
  end

  defp operation("==", [left, right], data) do
    {op1, op2} = cast_comparison_operator(resolve(left, data), resolve(right, data))

    op1 == op2
  end

  defp operation("!=", [left, right], data) do
    {op1, op2} = cast_comparison_operator(resolve(left, data), resolve(right, data))

    op1 != op2
  end

  defp operation("===", [left, right], data) do
    resolve(left, data) === resolve(right, data)
  end

  defp operation("!==", [left, right], data) do
    resolve(left, data) !== resolve(right, data)
  end

  defp operation("!!", [condition], data) do
    case resolve(condition, data) do
      resolved when resolved in @falsey -> false
      _truthy -> true
    end
  end

  defp operation("!!", condition, data) do
    operation("!!", [condition], data)
  end

  defp operation("!", condition, data) do
    !operation("!!", condition, data)
  end

  defp operation("max", [], _data), do: nil

  defp operation("max", list, data) when is_list(list) do
    # When reducing the list of resolved json logic, we need to try to coerce it
    # to a numeric value in order to find the largest number, but we need to
    # ensure we return the resolved value, and not the coerced numeric value.
    list
    |> Enum.reduce_while([], fn element, acc ->
      case resolve(element, data) do
        resolved when is_number(resolved) ->
          {:cont, [{resolved, resolved} | acc]}

        resolved when is_binary(resolved) ->
          if numeric_string?(resolved) do
            {:ok, parsed} = parse_number(resolved)
            {:cont, [{resolved, parsed} | acc]}
          else
            {:halt, nil}
          end
      end
    end)
    |> case do
      nil ->
        nil

      otherwise ->
        otherwise
        |> Enum.max_by(fn {_, num} -> num end)
        |> then(fn {resolved, _} -> resolved end)
    end
  end

  defp operation("min", [], _data), do: nil

  defp operation("min", list, data) when is_list(list) do
    # When reducing the list of resolved json logic, we need to try to coerce it
    # to a numeric value in order to find the smallest number, but we need to
    # ensure we return the resolved value, and not the coerced numeric value.
    list
    |> Enum.reduce_while([], fn element, acc ->
      case resolve(element, data) do
        resolved when is_number(resolved) ->
          {:cont, [{resolved, resolved} | acc]}

        resolved when is_binary(resolved) ->
          if numeric_string?(resolved) do
            {:ok, parsed} = parse_number(resolved)
            {:cont, [{resolved, parsed} | acc]}
          else
            {:halt, nil}
          end
      end
    end)
    |> case do
      nil ->
        nil

      otherwise ->
        otherwise
        |> Enum.min_by(fn {_, num} -> num end)
        |> then(fn {resolved, _} -> resolved end)
    end
  end

  defp operation("?:", logic, data), do: operation("if", logic, data)

  defp operation("if", [], _data), do: nil
  defp operation("if", [last], data), do: resolve(last, data)

  defp operation("if", [condition, yes], data) do
    case resolve(condition, data) do
      resolved when resolved in @falsey ->
        nil

      _resolved ->
        resolve(yes, data)
    end
  end

  defp operation("if", [condition, yes, no], data) do
    case resolve(condition, data) do
      resolved when resolved in @falsey ->
        resolve(no, data)

      _resolved ->
        resolve(yes, data)
    end
  end

  defp operation("if", [condition, yes | others], data) do
    case resolve(condition, data) do
      resolved when resolved in @falsey ->
        operation("if", others, data)

      _resolved ->
        resolve(yes, data)
    end
  end

  defp operation("missing", keys, data) when is_list(keys) and is_map(data) do
    Enum.filter(keys, &(operation("var", [&1, :missing], data) == :missing))
  end

  defp operation("missing", keys, _data) when is_list(keys), do: keys

  defp operation("missing", keys, data) do
    case resolve(keys, data) do
      resolved when is_list(resolved) ->
        operation("missing", resolved, data)

      resolved ->
        operation("missing", [resolved], data)
    end
  end

  defp operation("missing_some", [min, keys], data) do
    case operation("missing", keys, data) do
      list when length(keys) - length(list) < min ->
        list

      _otherwise ->
        []
    end
  end

  defp operation("<", [left, right], data) do
    case cast_comparison_operator(resolve(left, data), resolve(right, data)) do
      {nil, nil} -> true
      {nil, _op2} -> false
      {_op1, nil} -> false
      {op1, op2} -> op1 < op2
    end
  end

  defp operation("<", [left, middle, right | _], data) do
    operation("<", [left, middle], data) &&
      operation("<", [middle, right], data)
  end

  defp operation("<=", [left, right], data) do
    case cast_comparison_operator(resolve(left, data), resolve(right, data)) do
      {nil, nil} -> true
      {nil, _op2} -> false
      {_op1, nil} -> false
      {op1, op2} -> op1 <= op2
    end
  end

  defp operation("<=", [left, middle, right | _], data) do
    operation("<=", [left, middle], data) &&
      operation("<=", [middle, right], data)
  end

  defp operation(">", [left, right], data) do
    case cast_comparison_operator(resolve(left, data), resolve(right, data)) do
      {nil, nil} -> true
      {nil, _op2} -> false
      {_op1, nil} -> false
      {op1, op2} -> op1 > op2
    end
  end

  defp operation(">", [left, middle, right | _], data) do
    operation(">", [left, middle], data) &&
      operation(">", [middle, right], data)
  end

  defp operation(">=", [left, right], data) do
    case cast_comparison_operator(resolve(left, data), resolve(right, data)) do
      {nil, nil} -> true
      {nil, _op2} -> false
      {_op1, nil} -> false
      {op1, op2} -> op1 >= op2
    end
  end

  defp operation(">=", [left, middle, right | _], data) do
    operation(">=", [left, middle], data) &&
      operation(">=", [middle, right], data)
  end

  defp operation("+", [], _data), do: 0

  defp operation("+", numbers, data) when is_list(numbers) do
    numbers
    |> Enum.map(&resolve(&1, data))
    |> Enum.reduce(0, fn
      str, total when is_binary(str) ->
        {:ok, num} = parse_number(str)
        total + num

      num, total ->
        total + num
    end)
  end

  defp operation("+", numbers, data), do: operation("+", [numbers], data)

  defp operation("-", [], _data), do: nil

  defp operation("-", [first, last], data) do
    {op1, op2} = cast_comparison_operator(resolve(first, data), resolve(last, data))

    op1 - op2
  end

  defp operation("-", [first], data) do
    case resolve(first, data) do
      resolved when is_number(resolved) ->
        -resolved

      resolved ->
        if numeric_string?(resolved) do
          {:ok, parsed} = parse_number(resolved)
          -parsed
        else
          raise ArgumentError, "Unsupported operation `-` for `#{first}`"
        end
    end
  end

  defp operation("*", numbers, data) do
    numbers
    |> Enum.map(&resolve(&1, data))
    |> Enum.reduce(1, fn
      str, total when is_binary(str) ->
        if String.match?(str, ~r/\./) do
          {num, _} = Float.parse(str)
          total * num
        else
          {num, _} = Integer.parse(str)
          total * num
        end

      num, total ->
        total * num
    end)
  end

  defp operation("/", [first, last], data) do
    {op1, op2} = cast_comparison_operator(resolve(first, data), resolve(last, data))

    op1 / op2
  end

  defp operation("%", [first, last], data) do
    Kernel.rem(resolve(first, data), resolve(last, data))
  end

  defp operation("map", [list, map_action], data) do
    case resolve(list, data) do
      resolved when is_list(resolved) ->
        Enum.map(resolved, &resolve(map_action, &1))

      _resolved ->
        []
    end
  end

  defp operation("filter", [list, filter_action], data) do
    list
    |> resolve(data)
    |> Enum.filter(&operation("!!", filter_action, &1))
  end

  defp operation("reduce", [list, reduce_action], data) do
    operation("reduce", [list, reduce_action, nil], data)
  end

  defp operation("reduce", [list, reduce_action, first], data) do
    first_resolved = resolve(first, data)

    case resolve(list, data) do
      resolved when is_list(resolved) ->
        Enum.reduce(resolved, first_resolved, fn item, accumulator ->
          resolve(reduce_action, %{"current" => item, "accumulator" => accumulator})
        end)

      _resolved ->
        first
    end
  end

  defp operation("all", [list, test], data) do
    case resolve(list, data) do
      [] ->
        false

      resolved when is_list(resolved) ->
        Enum.all?(resolved, &resolve(test, &1))

      _resolved ->
        false
    end
  end

  defp operation("none", [list, test], data) do
    list
    |> resolve(data)
    |> Enum.all?(fn item -> Kernel.if(resolve(test, item), do: false, else: true) end)
  end

  defp operation("some", [list, test], data) do
    list
    |> resolve(data)
    |> Enum.any?(&resolve(test, &1))
  end

  defp operation("merge", [], _data), do: []

  defp operation("merge", [element | rest], data) do
    case resolve(element, data) do
      list when is_list(list) ->
        list ++ operation("merge", rest, data)

      element ->
        [element | operation("merge", rest, data)]
    end
  end

  defp operation("merge", element, data), do: [resolve(element, data)]

  defp operation("in", [member, list], data) when is_list(list) do
    list
    |> Enum.map(&resolve(&1, data))
    |> Enum.member?(resolve(member, data))
  end

  defp operation("in", [substring, string], data) when is_binary(string) do
    String.contains?(string, resolve(substring, data))
  end

  defp operation("in", [_, nil], _), do: false

  defp operation("in", [member, list], _) when not is_map(list) do
    raise ArgumentError, "Cannot apply `in` to non-enumerable: `#{inspect([member, list])}`"
  end

  defp operation("in", [find, from], data) do
    operation("in", [resolve(find, data), resolve(from, data)], data)
  end

  defp operation("cat", list, data) when is_list(list) do
    Enum.map_join(list, "", &resolve(&1, data))
  end

  defp operation("cat", string, data) do
    string
    |> resolve(data)
    |> to_string()
  end

  defp operation("substr", [string, offset], data) do
    string
    |> resolve(data)
    |> String.slice(offset..-1)
  end

  defp operation("substr", [string, offset, length], data) when length >= 0 do
    string
    |> resolve(data)
    |> String.slice(offset, length)
  end

  defp operation("substr", [string, offset, length], data) do
    string
    |> resolve(data)
    |> String.slice(offset..(length - 1))
  end

  defp operation("var", "", data), do: data

  defp operation("var", [path, default_key], data) do
    operation("var", path, data) || resolve(default_key, data)
  end

  defp operation("var", [path], data) do
    operation("var", path, data)
  end

  defp operation("var", path, data) when not is_number(path) do
    case resolve(path, data) do
      string when is_binary(string) ->
        string
        |> String.split(".")
        |> Enum.reduce(data, fn
          _key, nil ->
            nil

          key, acc when is_list(acc) ->
            {index, _} = Integer.parse(key)
            Enum.at(acc, index)

          key, acc when is_map(acc) ->
            Map.get(acc, key)

          _key, _acc ->
            nil
        end)

      _otherwise ->
        data
    end
  end

  defp operation("var", index, data) when is_number(index) do
    Enum.at(data, index)
  end

  defp operation("log", logic, data), do: resolve(logic, data)

  defp operation(name, _logic, _data),
    do: raise(ArgumentError, "Unrecognized operation `#{name}`")

  defp cast_comparison_operator(left, right) when is_number(left) and is_binary(right) do
    case parse_number(right) do
      {:ok, parsed} ->
        {left, parsed}

      _ ->
        raise ArgumentError, "Unable to parse number `#{right}`"
    end
  end

  defp cast_comparison_operator(left, right) when is_binary(left) and is_number(right) do
    case parse_number(left) do
      {:ok, parsed} ->
        {parsed, right}

      _ ->
        raise ArgumentError, "Unable to parse number `#{left}`"
    end
  end

  defp cast_comparison_operator(left, right) when is_binary(left) and is_binary(right) do
    if numeric_string?(left) and numeric_string?(right) do
      with {:ok, left} <- parse_number(left),
           {:ok, right} <- parse_number(right) do
        {left, right}
      else
        :error ->
          raise ArgumentError, "Unsupported numeric values `#{left}` and `#{right}`"
      end
    else
      {left, right}
    end
  end

  defp cast_comparison_operator(left, right), do: {left, right}

  @numeric_regex ~r/^[\+-]?(\d+)((\.(\d+)([eE][\-\+]?(\d+))?))?$/
  defp numeric_string?(value), do: String.match?(value, @numeric_regex)

  defp parse_number(value) do
    case Integer.parse(value) do
      {integer, ""} ->
        {:ok, integer}

      _ ->
        case Float.parse(value) do
          {float, ""} ->
            {:ok, float}

          {float, "."} ->
            {:ok, float}

          _ ->
            :error
        end
    end
  end
end
