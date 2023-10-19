function myfunc()
{
    echo 'some value'
    return 1
}

value=$(myfunc)
echo $?
echo $value

diskUsage="0.7971042551709729"
maxUsage="90"

diskUsageN=${diskUsage:2:2}
echo "an $diskUsageN"

if [[ $diskUsageN -ge $maxUsage ]]; then
  echo "disk usage greater or equal than max"
else
  echo "disk usage is smaller than max"
fi

